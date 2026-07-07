import re
from pathlib import Path

import pytest

from src.kg_schema import load_cypher_file

LAB_DIR = Path(__file__).resolve().parents[1] / "cypher" / "lab"

EXPECTED_FILES = [
    "01_first_five_nodes.cypher",
    "02_blast_radius.cypher",
    "03_three_questions.cypher",
    "04_break_it.cypher",
    "your_network_template.cypher",
    "starter_shapes.cypher",
]

# Labels/relationships that exist in the design seed, plus the simplified
# labels used only in the pre-seed sandbox block (01). A lab block using
# anything outside these sets is almost certainly a typo or an invented edge
# that will return zero rows against the real graph.
ALLOWED_LABELS = {
    # sandbox (block 01, pre-seed)
    "Router",
    # seed-real
    "OSPFArea", "BackboneArea", "NormalArea", "StubArea",
    "Device", "OSPFRouter", "ABR", "ASBR",
    "Prefix", "BusinessService", "Route", "ExternalRoute",
    "LSA", "RouterLSA", "NetworkLSA", "SummaryLSA", "ExternalLSA",
    "NSSALSA", "OpaqueLSA", "LSAType",
}
ALLOWED_RELS = {
    "CONNECTS", "ORIGINATES_IN", "ADVERTISED_BY", "HAS_LSA_TYPE",
    "SUPPORTS", "DEPENDS_ON", "RESTRICTS", "CARRIED_BY_LSA",
}

_BRACKET_RE = re.compile(r"\[[^\]]*\]")
_LABEL_RE = re.compile(r":([A-Z][A-Za-z0-9_]*)")
_REL_RE = re.compile(r"\[[A-Za-z0-9_]*:([A-Za-z0-9_]+)")


def _strip_comments(text: str) -> str:
    # Drop everything from the first // on each line (whole-line AND trailing
    # comments). A // inside a string literal would also be truncated, but the
    # lab blocks contain no such strings.
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def _labels(text: str) -> set[str]:
    # remove [ ... ] relationship segments so rel types aren't read as labels
    return set(_LABEL_RE.findall(_BRACKET_RE.sub(" ", text)))


def _rels(text: str) -> set[str]:
    return set(_REL_RE.findall(text))


@pytest.mark.parametrize("filename", EXPECTED_FILES)
def test_lab_file_exists_and_parses(filename):
    path = LAB_DIR / filename
    assert path.exists(), f"missing lab file: {path}"
    statements = load_cypher_file(path)
    assert statements, f"no Cypher statements parsed from {filename}"


@pytest.mark.parametrize("filename", EXPECTED_FILES)
def test_lab_file_uses_only_known_labels_and_rels(filename):
    body = _strip_comments((LAB_DIR / filename).read_text(encoding="utf-8"))
    bad_labels = _labels(body) - ALLOWED_LABELS
    bad_rels = _rels(body) - ALLOWED_RELS
    assert not bad_labels, f"{filename}: unknown labels {bad_labels}"
    assert not bad_rels, f"{filename}: unknown relationships {bad_rels}"


EXPECTED_STATEMENTS = {
    "01_first_five_nodes.cypher": 1,
    "02_blast_radius.cypher": 1,
    "03_three_questions.cypher": 3,
    "04_break_it.cypher": 2,
    "your_network_template.cypher": 1,
    "starter_shapes.cypher": 1,
}


@pytest.mark.parametrize("filename,expected", list(EXPECTED_STATEMENTS.items()))
def test_lab_file_statement_count(filename, expected):
    statements = load_cypher_file(LAB_DIR / filename)
    assert len(statements) == expected, (
        f"{filename}: expected {expected} statements, got {len(statements)}"
    )


def _seeded_driver():
    """Return a driver to a seeded DB, or skip if unavailable/unseeded."""
    from src.db import create_driver

    driver = None
    try:
        driver = create_driver()
        with driver.session() as session:
            count = session.run(
                "MATCH (a:OSPFArea {dataset:'vexpertai-design-ontology'}) "
                "RETURN count(a) AS c"
            ).single()["c"]
    except Exception as exc:  # noqa: BLE001 - any connection failure -> skip
        if driver is not None:
            driver.close()
        pytest.skip(f"Neo4j not available: {exc}")
    if count == 0:
        driver.close()
        pytest.skip("design dataset not loaded - run `make seed` first")
    return driver


def test_blast_radius_returns_order_api():
    driver = _seeded_driver()
    try:
        statement = load_cypher_file(LAB_DIR / "02_blast_radius.cypher")[-1]
        with driver.session() as session:
            rows = [record.data() for record in session.run(statement)]
    finally:
        driver.close()
    impacted = {svc for row in rows for svc in row.get("impacted_services", [])}
    assert "Order API" in impacted, f"expected Order API in {impacted}"


def test_blast_radius_clears_when_backbone_repaired():
    driver = _seeded_driver()
    statement = load_cypher_file(LAB_DIR / "02_blast_radius.cypher")[-1]
    set_state = (
        "MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->"
        "(:OSPFArea {area_id:'0.0.0.0'}) SET c.state=$state"
    )

    def impacted():
        with driver.session() as session:
            rows = [record.data() for record in session.run(statement)]
        return {svc for row in rows for svc in row.get("impacted_services", [])}

    try:
        with driver.session() as session:
            session.run(set_state, state="down")
        assert "Order API" in impacted()          # backbone down -> impact shown
        with driver.session() as session:
            session.run(set_state, state="up")
        assert impacted() == set()                 # backbone repaired -> impact gone
    finally:
        with driver.session() as session:
            session.run(set_state, state="down")   # restore seed default
        driver.close()
