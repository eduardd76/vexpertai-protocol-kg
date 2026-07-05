"""Application configuration shared by loaders and API."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Settings:
    neo4j_uri: str
    neo4j_username: str
    neo4j_password: str
    neo4j_database: str
    dataset: str = "vexpertai-design-ontology"


def get_settings() -> Settings:
    load_dotenv()
    return Settings(
        neo4j_uri=os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        neo4j_username=os.getenv("NEO4J_USERNAME", "neo4j"),
        neo4j_password=os.getenv("NEO4J_PASSWORD", "password123"),
        neo4j_database=os.getenv("NEO4J_DATABASE", "neo4j"),
    )
