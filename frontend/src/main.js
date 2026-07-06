import {
  listProfiles,
  loadGraph,
  loadProfile,
  loadTechnologyCatalog,
  previewProfile,
  saveProfile,
} from "./api.js";
import { renderGraph } from "./graphView.js";

const viewType = document.querySelector("#view-type");
const primaryInput = document.querySelector("#primary-input");
const secondaryInput = document.querySelector("#secondary-input");
const secondaryField = document.querySelector("#secondary-field");
const loadButton = document.querySelector("#load-view");
const graphContainer = document.querySelector("#graph");
const properties = document.querySelector("#node-properties");
const summary = document.querySelector("#summary");
const recommendations = document.querySelector("#recommendations");
const tabs = document.querySelectorAll(".tab");
const panels = document.querySelectorAll(".panel");
const profileName = document.querySelector("#profile-name");
const profileSites = document.querySelector("#profile-sites");
const profileNotes = document.querySelector("#profile-notes");
const technologyOptions = document.querySelector("#technology-options");
const previewProfileButton = document.querySelector("#preview-profile");
const saveProfileButton = document.querySelector("#save-profile");
const savedProfiles = document.querySelector("#saved-profiles");
const loadProfileButton = document.querySelector("#load-profile");
const builderStatus = document.querySelector("#builder-status");
const builderGraph = document.querySelector("#builder-graph");
const builderProperties = document.querySelector("#builder-node-properties");
const builderSummary = document.querySelector("#builder-summary");
const builderWarnings = document.querySelector("#builder-warnings");

let savedProfileRecords = new Map();

const defaults = {
  protocol: ["ospf", ""],
  interaction: ["ospf", "bgp"],
  service: ["Payment-App", ""],
  failure: ["Ethernet1/49", ""],
  change: ["CHG-8821", ""],
  search: ["Payment", ""],
};

function updateInputs() {
  const [primary, secondary] = defaults[viewType.value];
  primaryInput.value = primary;
  secondaryInput.value = secondary;
  secondaryField.classList.toggle("hidden", viewType.value !== "interaction");
}

function renderMessages(container, items, showEvidence = false) {
  container.replaceChildren();
  if (!items.length) {
    container.textContent = "None.";
    return;
  }
  for (const item of items) {
    const article = document.createElement("article");
    const name = document.createElement("strong");
    const action = document.createElement("p");
    name.textContent = item.name;
    action.textContent = item.action || "";
    article.append(name, action);
    if (showEvidence) {
      const evidence = document.createElement("p");
      evidence.className = "evidence";
      evidence.textContent = item.evidence
        ? `Evidence: ${item.evidence} (${item.evidence_source || "source unavailable"})`
        : "Evidence source unavailable.";
      article.append(evidence);
    }
    container.append(article);
  }
}

async function refresh() {
  loadButton.disabled = true;
  summary.textContent = "Loading…";
  try {
    const graph = await loadGraph(
      viewType.value,
      primaryInput.value.trim(),
      secondaryInput.value.trim(),
    );
    renderGraph(graphContainer, graph, (selected) => {
      properties.textContent = JSON.stringify(
        { type: selected.type, ...selected.properties },
        null,
        2,
      );
    });
    summary.textContent = graph.summary;
    renderMessages(recommendations, graph.recommendations, true);
  } catch (error) {
    summary.textContent = error.message;
  } finally {
    loadButton.disabled = false;
  }
}

function profilePayload() {
  const technologies = [
    ...technologyOptions.querySelectorAll("input[type=checkbox]:checked"),
  ].map((input) => input.value);
  return {
    name: profileName.value.trim(),
    technologies,
    sites: profileSites.value
      .split(",")
      .map((site) => site.trim())
      .filter(Boolean),
    notes: profileNotes.value.trim(),
  };
}

function renderBuilder(graph) {
  renderGraph(builderGraph, graph, (selected) => {
    builderProperties.textContent = JSON.stringify(
      { type: selected.type, ...selected.properties },
      null,
      2,
    );
  });
  builderSummary.textContent = graph.summary;
  renderMessages(builderWarnings, graph.recommendations);
}

function setBuilderBusy(busy) {
  previewProfileButton.disabled = busy;
  saveProfileButton.disabled = busy;
  loadProfileButton.disabled = busy;
}

async function previewBuilderProfile() {
  setBuilderBusy(true);
  builderStatus.textContent = "Building preview…";
  try {
    const graph = await previewProfile(profilePayload());
    renderBuilder(graph);
    builderStatus.textContent = "Preview uses the shared core and does not write to Neo4j.";
  } catch (error) {
    builderStatus.textContent = error.message;
  } finally {
    setBuilderBusy(false);
  }
}

async function refreshSavedProfiles() {
  const profiles = await listProfiles();
  savedProfileRecords = new Map(profiles.map((profile) => [profile.id, profile]));
  savedProfiles.replaceChildren(new Option("Select a profile", ""));
  for (const profile of profiles) {
    savedProfiles.add(new Option(profile.name, profile.id));
  }
}

async function saveBuilderProfile() {
  setBuilderBusy(true);
  builderStatus.textContent = "Saving profile…";
  try {
    const graph = await saveProfile(profilePayload());
    renderBuilder(graph);
    await refreshSavedProfiles();
    const profileNode = graph.nodes.find(
      (node) => node.type === "KnowledgeGraphProfile",
    );
    savedProfiles.value = profileNode?.id || "";
    builderStatus.textContent = "Profile saved in the unified Neo4j knowledge graph.";
  } catch (error) {
    builderStatus.textContent = error.message;
  } finally {
    setBuilderBusy(false);
  }
}

async function loadSavedProfile() {
  const profileId = savedProfiles.value;
  if (!profileId) {
    builderStatus.textContent = "Select a saved profile first.";
    return;
  }
  setBuilderBusy(true);
  try {
    const record = savedProfileRecords.get(profileId);
    profileName.value = record.name;
    profileSites.value = (record.sites || []).join(", ");
    for (const checkbox of technologyOptions.querySelectorAll(
      "input[type=checkbox]",
    )) {
      checkbox.checked = (record.technologies || []).includes(checkbox.value);
    }
    const graph = await loadProfile(profileId);
    renderBuilder(graph);
    builderStatus.textContent = "Saved profile loaded.";
  } catch (error) {
    builderStatus.textContent = error.message;
  } finally {
    setBuilderBusy(false);
  }
}

async function initializeBuilder() {
  try {
    const catalog = await loadTechnologyCatalog();
    technologyOptions.replaceChildren();
    const defaults = new Set(["layer2", "ospf", "bgp", "mpls", "qos", "security"]);
    for (const technology of catalog.technologies) {
      const label = document.createElement("label");
      label.className = "technology-option";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.value = technology.id;
      checkbox.checked = defaults.has(technology.id);
      const content = document.createElement("span");
      const name = document.createElement("strong");
      const description = document.createElement("span");
      name.textContent = technology.name;
      description.textContent = technology.description;
      content.append(name, document.createElement("br"), description);
      label.append(checkbox, content);
      technologyOptions.append(label);
    }
    await refreshSavedProfiles();
  } catch (error) {
    technologyOptions.textContent = error.message;
  }
}

for (const tab of tabs) {
  tab.addEventListener("click", () => {
    for (const item of tabs) item.classList.toggle("active", item === tab);
    for (const panel of panels) {
      panel.classList.toggle("hidden", panel.id !== tab.dataset.panel);
    }
  });
}

viewType.addEventListener("change", updateInputs);
loadButton.addEventListener("click", refresh);
previewProfileButton.addEventListener("click", previewBuilderProfile);
saveProfileButton.addEventListener("click", saveBuilderProfile);
loadProfileButton.addEventListener("click", loadSavedProfile);
updateInputs();
refresh();
initializeBuilder();
