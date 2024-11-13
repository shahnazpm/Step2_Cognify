from flask import Flask, render_template, request
import pickle
import pandas as pd
import os

app = Flask(__name__)

# Load the model from the models directory
model_path = os.path.join('models', 'prediction_model_test.pkl')
# model_path = os.path.join('models', 'prelim_rf_model.pkl')
with open(model_path, 'rb') as file:
    model = pickle.load(file)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict():
    # Get the uploaded file
    uploaded_file = request.files['file']

    if uploaded_file.filename.endswith('.csv'):
        # Read the CSV file into a DataFrame
        df = pd.read_csv(uploaded_file)

        # Ensure the DataFrame has the expected number of features
        if df.shape[1] == 365:  # Change this number to the expected number of features
            # Make predictions using the model
            predictions = model.predict(df)

            # States list
            states = [
                'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 
                'Colorado', 'Connecticut', 'Delaware', 'Florida', 'Georgia', 
                'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa', 
                'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 
                'Massachusetts', 'Michigan', 'Minnesota', 'Mississippi', 
                'Missouri', 'Montana', 'Nebraska', 'Nevada', 'New Hampshire', 
                'New Jersey', 'New Mexico', 'New York', 'North Carolina', 
                'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 
                'Rhode Island', 'South Carolina', 'South Dakota', 'Tennessee', 
                'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington', 
                'West Virginia', 'Wisconsin', 'Wyoming'
            ]

            # Create a JSON response
            results = {states[i]: int(prediction) for i, prediction in enumerate(predictions)}

            # Summary calculations
            democrat_count = sum(1 for prediction in predictions if prediction == 0)
            republican_count = sum(1 for prediction in predictions if prediction == 1)
            total_states = len(states)

            winning_party = "Democrat" if democrat_count > republican_count else "Republican"
            democrat_percentage = (democrat_count / total_states) * 100
            republican_percentage = (republican_count / total_states) * 100

            summary = {
                'total_states': total_states,
                'democrat_count': democrat_count,
                'republican_count': republican_count,
                'winning_party': winning_party,
                'democrat_percentage': democrat_percentage,
                'republican_percentage': republican_percentage,
                'democrat_states': [state for state, pred in results.items() if pred == 0],
                'republican_states': [state for state, pred in results.items() if pred == 1],
            }

            print(summary)
            # print(results)
            # print(json.dumps(results, indent=4))
            return render_template('result.html', results=results, summary=summary)

        return "Error: CSV must contain 365 features."

    return "Error: Please upload a valid CSV file."


if __name__ == '__main__':
    app.run(debug=True)
