import pytest
import httpx

# Universal test configuration
ENDPOINTS = {
    "vllm": {"url": "http://localhost:8000/v1/completions", "payload": {"model": "gpt2", "prompt": "Hello, world!", "max_tokens": 5}},
    "clip": {"url": "http://localhost:8001/vision", "payload": {"text": "A cat"}},
    "embedding": {"url": "http://localhost:8002/embed", "payload": {"text": "A sentence"}},
}

@pytest.mark.parametrize("service", ENDPOINTS.keys())
def test_service_responds(service):
    """Test that each service endpoint responds with status 200 and valid JSON."""
    url = ENDPOINTS[service]["url"]
    payload = ENDPOINTS[service]["payload"]
    with httpx.Client(timeout=10) as client:
        response = client.post(url, json=payload)
        assert response.status_code == 200, f"{service} did not return 200"
        assert response.headers["content-type"].startswith("application/json"), f"{service} did not return JSON"
        data = response.json()
        assert isinstance(data, dict), f"{service} did not return a dict"

@pytest.mark.parametrize("service", ENDPOINTS.keys())
def test_service_error_handling(service):
    """Test that each service handles bad input gracefully (returns 4xx or 5xx)."""
    url = ENDPOINTS[service]["url"]
    with httpx.Client(timeout=10) as client:
        response = client.post(url, json={})
        assert response.status_code >= 400, f"{service} did not return error for bad input"

# Additional test: vLLM OpenAI-compatible endpoint health
@pytest.mark.skipif("vllm" not in ENDPOINTS, reason="vLLM endpoint not configured")
def test_vllm_openai_compat():
    url = ENDPOINTS["vllm"]["url"]
    payload = ENDPOINTS["vllm"]["payload"]
    with httpx.Client(timeout=10) as client:
        response = client.post(url, json=payload, headers={"Authorization": "Bearer my-secret-key"})
        assert response.status_code == 200
        data = response.json()
        assert "choices" in data
        assert isinstance(data["choices"], list) 