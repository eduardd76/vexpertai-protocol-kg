"""FastAPI graph views for the unified vExpertAI knowledge graph."""

from __future__ import annotations

from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from .config import PROJECT_ROOT
from .db import create_driver
from .graph_queries import GraphQueries
from .kg_builder import KGBuilder, ProfileInput


class KGProfileRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    technologies: list[str] = Field(min_length=1, max_length=20)
    sites: list[str] = Field(default_factory=list, max_length=50)
    notes: str = Field(default="", max_length=500)

    def to_profile(self) -> ProfileInput:
        return ProfileInput(
            name=self.name,
            technologies=tuple(self.technologies),
            sites=tuple(self.sites),
            notes=self.notes,
        )


@asynccontextmanager
async def lifespan(app: FastAPI):
    driver = create_driver()
    app.state.driver = driver
    app.state.graph_queries = GraphQueries(driver)
    app.state.kg_builder = KGBuilder(driver)
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
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


def get_graph_queries(request: Request) -> GraphQueries:
    return request.app.state.graph_queries


def get_kg_builder(request: Request) -> KGBuilder:
    return request.app.state.kg_builder


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


@app.get("/kg-builder/catalog")
def builder_catalog(
    builder: KGBuilder = Depends(get_kg_builder),
) -> dict[str, Any]:
    return builder.catalog()


@app.post("/kg-builder/preview")
def preview_profile(
    request: KGProfileRequest,
    builder: KGBuilder = Depends(get_kg_builder),
) -> dict[str, Any]:
    try:
        return builder.preview(request.to_profile())
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.post("/kg-builder/profiles")
def save_profile(
    request: KGProfileRequest,
    builder: KGBuilder = Depends(get_kg_builder),
) -> dict[str, Any]:
    try:
        return builder.save(request.to_profile())
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error


@app.get("/kg-builder/profiles")
def list_profiles(
    builder: KGBuilder = Depends(get_kg_builder),
) -> list[dict[str, Any]]:
    return builder.list_profiles()


@app.get("/views/profile/{profile_id}")
def profile_view(
    profile_id: str,
    builder: KGBuilder = Depends(get_kg_builder),
) -> dict[str, Any]:
    graph = builder.get_profile(profile_id)
    if graph is None:
        raise HTTPException(status_code=404, detail="Knowledge graph profile not found.")
    return graph


FRONTEND_DIR = PROJECT_ROOT / "frontend"
if FRONTEND_DIR.exists():
    app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="frontend")
