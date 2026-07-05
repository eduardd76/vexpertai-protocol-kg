"""Helpers for loading the two MVP scenarios."""

from pathlib import Path

from neo4j import Driver

from kg_schema import CYPHER_DIR, execute_cypher_file


SEED_FILES: tuple[Path, ...] = (
    CYPHER_DIR / "seed_overlay_underlay.cypher",
    CYPHER_DIR / "seed_redistribution.cypher",
)


def load_seed_data(driver: Driver) -> dict[str, int]:
    """Load both seed files and return statement counts by filename."""
    return {
        path.name: execute_cypher_file(driver, path)
        for path in SEED_FILES
    }
