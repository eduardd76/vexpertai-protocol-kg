"""FastAPI graph views for the unified vExpertAI knowledge graph."""

from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import Depends, FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import PROJECT_ROOT
from .db import create_driver
from .graph_queries import GraphQueries


@asynccontextmanager
async def lifespan(app: FastAPI):
    driver = create_driver()
    app.state.driver = driver
    app.state.graph_queries = GraphQueries(driver)
    try:
        yield
    finally:
        driver.close()


app = FastAPI(
    title="vExpertAI Network Design Knowledge Graph",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


def get_graph_queries(request: Request) -> GraphQueries:
    return request.app.state.graph_queries


@app.get("/health")
def health(queries: GraphQueries = Depends(get_graph_queries)) -> dict[str, Any]:
    return queries.health()


@app.get("/views/protocol/{protocol}")
def protocol_view(
    protocol: str, queries: GraphQueries = Depends(get_graph_queries)
) -> dict[str, Any]:
    return queries.protocol_view(protocol)


@app.get("/views/interaction/{source_protocol}/{target_protocol}")
def interaction_view(
    source_protocol: str,
    target_protocol: str,
    queries: GraphQueries = Depends(get_graph_queries),
) -> dict[str, Any]:
    return queries.interaction_view(source_protocol, target_protocol)


@app.get("/views/service/{service_name}")
def service_view(
    service_name: str, queries: GraphQueries = Depends(get_graph_queries)
) -> dict[str, Any]:
    return queries.service_view(service_name)


@app.get("/views/failure/{entity_name:path}")
def failure_view(
    entity_name: str, queries: GraphQueries = Depends(get_graph_queries)
) -> dict[str, Any]:
    return queries.failure_view(entity_name)


@app.get("/views/change/{change_id}")
def change_view(
    change_id: str, queries: GraphQueries = Depends(get_graph_queries)
) -> dict[str, Any]:
    return queries.change_view(change_id)


@app.get("/search")
def search(
    q: str = Query(min_length=1),
    queries: GraphQueries = Depends(get_graph_queries),
) -> dict[str, Any]:
    return queries.search(q)


FRONTEND_DIR = PROJECT_ROOT / "frontend"
if FRONTEND_DIR.exists():
    app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="frontend")
