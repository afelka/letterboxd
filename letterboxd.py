import pandas as pd
import matplotlib.pyplot as plt

#to export your own data
#Log into Letterboxd.
#Click on your username on the top navigation
#Click on “settings”
#Now click on the tab “Import & Export”
#Click on “Export your data”

movies =  pd.read_csv("diary.csv")
ratings = pd.read_csv("ratings.csv")

movies['Watched Date'] = pd.to_datetime(movies['Watched Date'])

# Total number of movies watched
total_movies_watched = movies.shape[0]

# Filter dataset from 2017
movies = movies[movies['Watched Date'].dt.year >= 2017]

# Total number of movies watched since 2017
total_movies_watched_since_2017 = movies.shape[0]

# Extract the month and year from the 'watched_date' column
movies['month_year'] = movies['Watched Date'].dt.to_period('M')

# Count the number of movies watched each month
monthly_counts = movies['month_year'].value_counts().sort_index()

# Plot a histogram of watched dates
plt.figure(figsize=(12, 6))
monthly_counts.plot(kind='bar', color='skyblue')
plt.title('Movies Watched Monthly')
plt.xlabel('Month')
plt.ylabel('Number of Movies Watched')

# Add labels to each bar
for index, value in enumerate(monthly_counts):
    plt.text(index, value, str(value), ha='center', va='bottom', fontsize=8)

# Adjust x-axis labels
plt.xticks(rotation=45, ha='right')  # Rotate the labels for better readability
plt.tick_params(axis='x', labelsize=6)  # Adjust the font size of x-axis labels

# Add a text box with the total number of movies watched
plt.text(0.075, 0.85, f'Total Movies Watched: {total_movies_watched}', transform=plt.gcf().transFigure,
         fontsize=12, color='red', ha='left')

# Add a text box with the total number of movies watched since 2017
plt.text(0.075, 0.8, f'Total Movies Watched since 2017: {total_movies_watched_since_2017}', transform=plt.gcf().transFigure,
         fontsize=12, color='orange', ha='left')

# Show the plot
plt.tight_layout()

# Save the plot as a JPG file
plt.savefig('movies_watched_monthly.jpg', dpi=300)

plt.show()

#2nd plot with monthly totals

# Filter movies watched from 2017 to 2023
movies_filtered = movies[(movies['Watched Date'].dt.year >= 2017) & (movies['Watched Date'].dt.year <= 2023)]

# Extract the month from the 'watched_date' column
movies_filtered['month'] = movies_filtered['Watched Date'].dt.month

# Count the number of movies watched each month across the years
monthly_totals = movies_filtered['month'].value_counts().sort_index()

# Plot a bar chart for monthly totals across the specified years
plt.figure(figsize=(10, 6))
bar_plot = monthly_totals.plot(kind='bar', color='skyblue')
plt.title('Total Movies Watched Each Month (2017-2023)')
plt.xlabel('Month')
plt.ylabel('Number of Movies Watched')

# Add labels to each bar
for index, value in enumerate(monthly_totals):
    plt.text(index, value, str(value), ha='center', va='bottom', fontsize=8)

# Customize x-axis labels to show only the numbers for months
plt.xticks(range(len(monthly_totals.index)), monthly_totals.index, rotation=0, ha='center', fontsize=8, fontdict={'weight': 'bold'})

# Save the plot as a JPG file
plt.tight_layout()
plt.savefig('monthly_totals.jpg', dpi=300)  # Adjust dpi for higher resolution

# Show the plot
plt.show()

#3rd plot regarding ratings

# Combine 0.5 and 1 ratings into a single category
ratings['Rating'] = ratings['Rating'].replace({0.5: 1})

# Combine 1.5 and 1 ratings into a single category
ratings['Rating'] = ratings['Rating'].replace({1.5: 1})

# Count the number of movies per rating
rating_counts = ratings['Rating'].value_counts().sort_index()

# Calculate the percentage based on the 'Rating' column
rating_percentages = (rating_counts / len(ratings)) * 100

# Create a pie chart
colors = ['gold', 'lightcoral', 'lightblue', 'lightgreen', 'lightskyblue']
plt.pie(rating_percentages, labels=rating_counts.index, autopct='%1.1f%%', colors=colors, startangle=100)
plt.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.
plt.title('Rating Percentages', color = 'red')

# Save the plot as a JPG file
plt.savefig('rating_percentages.jpg', dpi=300)

plt.show()

# Filter movies with 5-star ratings and create a table output
five_star_movies = ratings[['Name', 'Year', 'Rating']][ratings['Rating'] == 5].sort_values(by='Year', ascending=False)

# Plotting the table using matplotlib
fig, ax = plt.subplots(figsize=(8, 4))
ax.axis('off')  # Hide axis
ax.table(cellText=five_star_movies.head(20).values, colLabels=five_star_movies.head(20).columns, cellLoc='center', loc='center')

# Save the figure as a JPG file
plt.savefig('last_20_movies_with_5_stars.jpg', format='jpg', bbox_inches='tight', pad_inches=0.1, dpi = 300)
plt.show()