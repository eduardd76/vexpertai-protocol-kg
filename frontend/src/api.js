const encode = encodeURIComponent;

export async function loadGraph(viewType, primary, secondary) {
  const routes = {
    protocol: `/views/protocol/${encode(primary)}`,
    interaction: `/views/interaction/${encode(primary)}/${encode(secondary)}`,
    service: `/views/service/${encode(primary)}`,
    failure: `/views/failure/${encode(primary)}`,
    change: `/views/change/${encode(primary)}`,
    search: `/search?q=${encode(primary)}`,
  };

  const response = await fetch(routes[viewType]);
  if (!response.ok) {
    throw new Error(`Graph request failed: ${response.status}`);
  }
  return response.json();
}

async function request(path, options = {}) {
  const response = await fetch(path, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(body.detail || `Request failed: ${response.status}`);
  }
  return response.json();
}

export function loadTechnologyCatalog() {
  return request("/kg-builder/catalog");
}

export function previewProfile(profile) {
  return request("/kg-builder/preview", {
    method: "POST",
    body: JSON.stringify(profile),
  });
}

export function saveProfile(profile) {
  return request("/kg-builder/profiles", {
    method: "POST",
    body: JSON.stringify(profile),
  });
}

export function listProfiles() {
  return request("/kg-builder/profiles");
}

export function loadProfile(profileId) {
  return request(`/views/profile/${encode(profileId)}`);
}
