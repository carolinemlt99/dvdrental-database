--Caroline Langridge
--ID 001470808

SELECT * FROM detailed_table;
DROP TABLE detailed_table;

SELECT * FROM summary_table;
DROP TABLE summary_table;

--function

CREATE OR REPLACE FUNCTION month_finder (rental_date timestamp)
	RETURNS int
	LANGUAGE plpgsql
AS
$$
DECLARE month_of_rental int;
BEGIN
	SELECT EXTRACT (MONTH FROM rental_date)  INTO month_of_rental;
RETURN month_of_rental;
END
$$

--detailed_table

SELECT
    amount,
	rental.rental_id,
	rental.rental_date,
	month_finder(rental.rental_date) AS rental_month,
	inventory.inventory_id,
	film_category.film_id,
	category.category_id,
	name
INTO detailed_table
FROM payment
INNER JOIN rental
	ON payment.rental_id = rental.rental_id
INNER JOIN inventory
    ON rental.inventory_id = inventory.inventory_id
INNER JOIN film_category
    ON inventory.film_id = film_category.film_id
INNER JOIN category
    ON film_category.category_id = category.category_id
	ORDER BY rental_date;

--summary_table

SELECT
	name,
    SUM(amount)
INTO summary_table
FROM detailed_table
	GROUP BY name
	ORDER BY sum DESC; 

-- trigger

CREATE OR REPLACE FUNCTION trigger_function()
	RETURNS TRIGGER
	LANGUAGE PLPGSQL
AS
$$
BEGIN
	DELETE FROM summary_table;
	INSERT INTO summary_table
	SELECT
	name,
    SUM(amount)
FROM detailed_table
	GROUP BY name
	ORDER BY sum DESC; 
	RETURN NEW;
END
$$

CREATE OR REPLACE TRIGGER new_summary_data
	AFTER UPDATE
	ON detailed_table
	FOR EACH STATEMENT
	EXECUTE PROCEDURE trigger_function();

--stored procedure

DROP PROCEDURE refresh_tables;

CREATE OR REPLACE PROCEDURE refresh_tables()
	LANGUAGE PLPGSQL
AS
$$
BEGIN
	DELETE FROM detailed_table;
	DELETE FROM summary_table;
	
	INSERT INTO detailed_table
	SELECT
    amount,
	rental.rental_id,
	rental.rental_date,
	month_finder(rental.rental_date) AS rental_month,
	inventory.inventory_id,
	film_category.film_id,
	category.category_id,
	name
FROM payment
INNER JOIN rental
	ON payment.rental_id = rental.rental_id
INNER JOIN inventory
    ON rental.inventory_id = inventory.inventory_id
INNER JOIN film_category
    ON inventory.film_id = film_category.film_id
INNER JOIN category
    ON film_category.category_id = category.category_id
	ORDER BY rental_date;

	INSERT INTO summary_table
	SELECT
	name,
    SUM(amount)
FROM detailed_table
	GROUP BY name
	ORDER BY sum DESC; 
	RETURN;
END;
$$

--check tables

SELECT * FROM detailed_table;

SELECT * FROM detailed_table
ORDER BY name DESC;

UPDATE detailed_table
SET name = 'VideoGames'
WHERE category_id = 10;

CALL refresh_tables();

SELECT * FROM summary_table;
