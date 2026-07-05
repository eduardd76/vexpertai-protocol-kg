from pathlib import Path

from src.kg_schema import split_cypher_statements


ROOT = Path(__file__).resolve().parents[1]
GLOBAL_SEED = ROOT / "cypher" / "seed" / "global_end_to_end_seed.cypher"
GLOBAL_QUERIES = (
    ROOT / "cypher" / "queries" / "global_network_design_queries.cypher"
)


def test_global_seed_contains_end_to_end_governance_chain() -> None:
    seed = GLOBAL_SEED.read_text(encoding="utf-8")

    for identifier in (
        "global-business-payment",
        "global-application-payment",
        "global-change-pl-payment",
        "global-cpdep-payment-redist",
        "global-dpdep-payment-mpls",
        "global-risk-payment-route-loss",
        "global-recommendation-payment",
        "global-validation-payment",
    ):
        assert identifier in seed


def test_global_query_pack_has_all_required_questions() -> None:
    statements = split_cypher_statements(
        GLOBAL_QUERIES.read_text(encoding="utf-8")
    )

    assert len(statements) == 7
    assert all("RETURN" in statement for statement in statements)
