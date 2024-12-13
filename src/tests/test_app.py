import pytest
import sys
import os
from unittest.mock import MagicMock

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

# Mocking BigQuery client
@pytest.fixture
def mock_bigquery(mocker):
    mock_bq_client = MagicMock()
    mocker.patch("app.bq_client", mock_bq_client)
    return mock_bq_client

def test_home_route(client, mock_bigquery):
    """
    Test the home route to ensure it returns the expected result page.
    """
    # Mock the BigQuery result
    mock_df = pd.DataFrame(columns=[f"feature_{i}" for i in range(371)], data=[[1]*371])
    mock_bigquery.query.return_value.to_dataframe.return_value = mock_df

    response = client.get('/')
    assert response.status_code == 200
    assert b"Winning Party:" in response.data or b"Summary" in response.data

def test_missing_target_column(client, mock_bigquery):
    """
    Test the behavior when 'Target' column is missing in BigQuery.
    """
    # Mock the BigQuery result without 'Target' column
    mock_df = pd.DataFrame(columns=[f"feature_{i}" for i in range(371)], data=[[1]*371])
    mock_bigquery.query.return_value.to_dataframe.return_value = mock_df

    response = client.get('/')
    assert response.status_code == 200
    assert b"Error: 'Target' column is missing in the BigQuery dataset." in response.data

def test_incorrect_bigquery_structure(client, mock_bigquery):
    """
    Test the behavior when the BigQuery data structure is incorrect.
    """
    # Mock BigQuery with incorrect structure (less than 371 columns)
    mock_df = pd.DataFrame(columns=[f"feature_{i}" for i in range(370)], data=[[1]*370])
    mock_bigquery.query.return_value.to_dataframe.return_value = mock_df

    response = client.get('/')
    assert response.status_code == 200
    assert b"Error: BigQuery dataset must contain 371 features." in response.data
