import pytest
import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app


@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_route(client):
    """
    Test the home route to ensure it returns the expected result page
    when the '2023_test_data.csv' file exists and has the correct structure.
    """
    response = client.get('/')
    assert response.status_code == 200

    print(response.data.decode())

    assert b"Winning Party:" in response.data or b"Summary" in response.data


def test_missing_csv_file(client, monkeypatch):
    """
    Test the behavior when the '2023_test_data.csv' file is missing.
    """
    monkeypatch.setattr("os.path.exists", lambda x: False)

    response = client.get('/')
    assert response.status_code == 200
    assert b"Error: The file '2023_test_data.csv' was not found." in response.data

def test_incorrect_csv_structure(client, monkeypatch, tmp_path):
    """
    Test the behavior when the CSV file has an incorrect structure.
    """
    incorrect_csv_path = tmp_path / "2023_test_data.csv"
    incorrect_csv_path.write_text("A,B,C\n1,2,3\n4,5,6") 

    monkeypatch.setattr("os.path.join", lambda *args: str(incorrect_csv_path))

    response = client.get('/')
    assert response.status_code == 200
    assert b"Error: CSV must contain 371 features." in response.data
