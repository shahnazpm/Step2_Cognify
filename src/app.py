from flask import Flask, render_template, request
import pickle
import pandas as pd
import os

app = Flask(__name__)

model_path = os.path.join('models', 'prelim_rf_model.pkl')
with open(model_path, 'rb') as file:
	model = pickle.load(file)

# Dictionary of states and their seat counts
# states_dict = {
#     'Alabama': 7, 'Alaska': 3, 'Arizona': 11, 'Arkansas': 6, 'California': 54,
#     'Colorado': 10, 'Connecticut': 7, 'Delaware': 3, 'Florida': 30, 'Georgia': 16,
#     'Hawaii': 4, 'Idaho': 4, 'Illinois': 21, 'Indiana': 11, 'Iowa': 6, 'Kansas': 6,
#     'Kentucky': 8, 'Louisiana': 8, 'Maine': 4, 'Maryland': 10, 'Massachusetts': 11,
#     'Michigan': 15, 'Minnesota': 10, 'Mississippi': 6, 'Missouri': 10, 'Montana': 4,
#     'Nebraska': 5, 'Nevada': 6, 'New Hampshire': 4, 'New Jersey': 14, 'New Mexico': 5,
#     'New York': 28, 'North Carolina': 14, 'North Dakota': 3, 'Ohio': 17, 'Oklahoma': 7,
#     'Oregon': 7, 'Pennsylvania': 20, 'Rhode Island': 4, 'South Carolina': 7, 'South Dakota': 3,
#     'Tennessee': 11, 'Texas': 40, 'Utah': 6, 'Vermont': 3, 'Virginia': 13, 'Washington': 12,
#     'West Virginia': 5, 'Wisconsin': 10, 'Wyoming': 3
# }
states_dict = {
	'Alabama': 7,
	'Alaska': 3,
	'Arizona': 11,
	'Arkansas': 6,
	'California': 54,
	'Colorado': 10,
	'Connecticut': 7,
	'Delaware': 3,
	'Florida': 30,
	'Georgia': 16,
	'Hawaii': 4,
	'Idaho': 4,
	'Illinois': 21,
	'Indiana': 11,
	'Iowa': 6,
	'Kansas': 6,
	'Kentucky': 8,
	'Louisiana': 8,
	'Maine': 4,
	'Maryland': 10,
	'Massachusetts': 11,
	'Michigan': 15,
	'Minnesota': 10,
	'Mississippi': 6,
	'Missouri': 10,
	'Montana': 4,
	'Nebraska': 5,
	'Nevada': 6,
	'New Hampshire': 4,
	'New Jersey': 14,
	'New Mexico': 5,
	'New York': 28,
	'North Carolina': 14,
	'North Dakota': 3,
	'Ohio': 17,
	'Oklahoma': 7,
	'Oregon': 7,
	'Pennsylvania': 20,
	'Rhode Island': 4,
	'South Carolina': 7,
	'South Dakota': 3,
	'Tennessee': 11,
	'Texas': 40,
	'Utah': 6,
	'Vermont': 3,
	'Virginia': 13,
	'Washington': 12,
	'West Virginia': 5,
	'Wisconsin': 10,
	'Wyoming': 3
}


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

		# Ensure the DataFrame has the expected number of features (371)
		if df.shape[1] == 371:
			# Drop the target column ('Target')
			X = df.drop(columns=['Target']) # Drop the 'Target' column

			# Make predictions using the model
			predictions = model.predict(X)
			print('predictions:', len(predictions))
	
			# Generate results using states_dict keys
			states = list(states_dict.keys())
			results = {states[i]: int(prediction) for i, prediction in enumerate(predictions)}

			# Summary calculations
			democrat_count = sum(1 for prediction in predictions if prediction == 0)
			republican_count = sum(1 for prediction in predictions if prediction == 1)
			total_states = len(states)

			winning_party = "Democrat" if democrat_count > republican_count else "Republican"
			democrat_percentage = (democrat_count / total_states) * 100
			republican_percentage = (republican_count / total_states) * 100

			# Calculate seats won by each party
			democrat_seats = sum(seats for state, seats in states_dict.items() if results[state] == 0)
			republican_seats = sum(seats for state, seats in states_dict.items() if results[state] == 1)

			summary = {
				'total_states': total_states,
				'democrat_count': democrat_count,
				'republican_count': republican_count,
				'winning_party': winning_party,
				'democrat_percentage': democrat_percentage,
				'republican_percentage': republican_percentage,
				'democrat_seats': democrat_seats,
				'republican_seats': republican_seats,
				'democrat_states': [state for state, pred in results.items() if pred == 0],
				'republican_states': [state for state, pred in results.items() if pred == 1],
			}

			# Render results and summary in the result HTML page
			return render_template('result.html', results=results, summary=summary)

		# Error message if the CSV file does not have the correct feature count
		return "Error: CSV must contain 371 features."

	return "Error: Please upload a valid CSV file."


if __name__ == '__main__':
	app.run(debug=True)
