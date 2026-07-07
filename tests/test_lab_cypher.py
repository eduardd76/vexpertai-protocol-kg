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
    return "\n".join(
        line for line in text.splitlines() if not line.strip().startswith("//")
    )


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
