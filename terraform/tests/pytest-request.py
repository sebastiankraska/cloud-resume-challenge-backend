# when using this local use a virtual environment, e.g. cd backend / python -m venv .venv / source .venv/bin/activate 
# tip: to use breakpoints in vs code, use backup-launch.json
import requests
import pytest

url = "https://jtfl70z8wd.execute-api.eu-central-1.amazonaws.com/visitor-count"
response = requests.get(url)
data = response.json()

def test_endpoint_returns_200():
    assert response.status_code == 200

def test_endpoint_returns_json():
    assert response.headers.get('Content-Type') == 'application/json'

def test_response_contains_visits():
    assert 'visits' in data

def test_visits_is_integer():
    assert isinstance(data['visits'], int)

def test_visits_is_positive():
    assert data['visits'] > 0

second_response = requests.get(url)
second_data = second_response.json()
def test_counter_increases_on_another_try():
    assert second_data['visits'] > data['visits']

