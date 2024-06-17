CREATE DATABASE restaurant;
USE restaurant;
-- --Question 1: - We need to find out the total visits to all restaurants under all alcohol categories available.
SELECT * from geoplaces2;
SELECT 
      g.Alcohol AS Alcohol_Category,
      COUNT(*) AS Total_Visits 
FROM 
      geoplaces2 g
JOIN 
      rating_final r ON g.placeID = r.placeID
GROUP BY 
	g.Alcohol
ORDER BY 
      Total_Visits DESC;
-- --Question 2: -Let's find out the average rating according to alcohol and price so that we can understand the rating in respective price categories as well.
SELECT
    g.Alcohol AS Alcohol_Category,
    g.Price AS Price_Category,
    AVG(r.Rating) AS Average_Rating
FROM
    geoplaces2 g
INNER JOIN
    rating_final r ON g.placeID = r.placeID
GROUP BY
    g.Alcohol,
    g.Price
ORDER BY
    g.Alcohol,
    g.Price;

-- --Question 3:  Let’s write a query to quantify that what are the parking availability as well in different alcohol categories along with the total number of restaurants.

SELECT
    g.Alcohol AS Alcohol_Category, 
    p.Parking_lot AS Parking_Availability,
    COUNT(DISTINCT g.placeID) AS Total_Restaurants
FROM
    geoplaces2 g
LEFT JOIN
    Chefmozparking p ON g.placeID = p.placeID
GROUP BY
    g.Alcohol, p.Parking_lot
ORDER BY
    g.Alcohol, p.Parking_lot;

-- --Question 4: -Also take out the percentage of different cuisine in each alcohol type.

WITH CuisineAlcoholCounts AS (
  SELECT
    GREATEST(COALESCE(gp.Alcohol, 'N/A'), 'N/A') AS Alcohol,
    cu.Rcuisine AS Cuisine,
    COUNT(*) AS Count
  FROM geoplaces2 gp
  LEFT JOIN Chefmozaccepts ga ON gp.placeID= ga.placeID
  LEFT JOIN Chefmozcuisine cu ON gp.placeID = cu.placeID
  WHERE gp.Alcohol IS NOT NULL
  GROUP BY Alcohol, cu.Rcuisine
),

TotalCuisineCounts AS (
  SELECT
    GREATEST(COALESCE(gp.Alcohol, 'N/A'), 'N/A') AS Alcohol,
    COUNT(*) AS TotalCount
  FROM geoplaces2 gp
  LEFT JOIN Chefmozaccepts ga ON gp.placeID = ga.placeID
  WHERE gp.Alcohol IS NOT NULL
  GROUP BY Alcohol
)

SELECT
  cac.Alcohol,
  cac.Cuisine,
  cac.Count,
  tcc.TotalCount,
  (CAST(cac.Count AS FLOAT) / tcc.TotalCount) * 100 AS Percentage
FROM CuisineAlcoholCounts cac
JOIN TotalCuisineCounts tcc ON cac.Alcohol = tcc.Alcohol
ORDER BY cac.Alcohol, Percentage DESC;

-- --Questions 5: - let’s take out the average rating of each state.
SELECT
    g.State,
    AVG(r.Rating) AS Average_Rating
FROM
    geoplaces2 g
INNER JOIN
    rating_final r ON g.placeID = r.placeID
GROUP BY
    g.State
ORDER BY
    Average_Rating DESC;

-- --Questions 6: -' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest rated by providing the summary on the basis of State, alcohol, 
-- --and Cuisine.
WITH StateAlcoholCuisineRatings AS (
    SELECT
        g.State AS state,
        g.Alcohol AS alcohol,
        uc.Rcuisine AS cuisine,
        AVG(r.Rating) AS avg_rating
    FROM
        geoplaces2 g
    JOIN
        rating_final r ON g.placeID = r.placeID
    JOIN
        chefmozcuisine c ON g.placeID = c.placeID
    JOIN
        Userprofile u ON r.userID = u.userID
    JOIN
        Usercuisine uc ON u.userID = uc.userID
    WHERE
        g.State IS NOT NULL
        AND g.Alcohol IS NOT NULL
        AND uc.Rcuisine IS NOT NULL
    GROUP BY
        g.State,
        g.Alcohol,
        uc.Rcuisine
)

SELECT
    sacr.state,
    sacr.alcohol,
    sacr.cuisine,
    sacr.avg_rating
FROM (
    SELECT
        state,
        MIN(avg_rating) AS min_avg_rating
    FROM
        StateAlcoholCuisineRatings
    GROUP BY
        state
) min_ratings
JOIN
    StateAlcoholCuisineRatings sacr ON min_ratings.state = sacr.state AND min_ratings.min_avg_rating = sacr.avg_rating
WHERE
    sacr.state = 'Tamaulipas';
    

-- --Question 7:  - Find the average weight, food rating, and service rating of the customers who have visited KFC and tried Mexican or Italian types of cuisine, and also 
-- --their budget level is low. We encourage you to give it a try by not using joins.

SELECT
    AVG(up.weight) AS avg_weight,
    AVG(rf.food_rating) AS avg_food_rating,
    AVG(rf.service_rating) AS avg_service_rating
FROM
    userprofile AS up,
    rating_final AS rf,
    usercuisine AS uc,
    userpayment AS ut
WHERE
    up.userID = rf.userID
    AND up.budget= 'low'
    AND rf.placeID IN (
        SELECT
            DISTINCT cp.placeID
        FROM
            Chefmozaccepts cp,
            Chefmozcuisine cu
        WHERE
            cu.placeID = cp.placeID
            AND cp.Rpayment = 'cash'
    )
    AND uc.userID = up.userID
    AND (uc.Rcuisine = 'Mexican' OR uc.Rcuisine = 'Italian')
    AND ut.userID = up.userID
    AND ut.Upayment = 'cash'
;
