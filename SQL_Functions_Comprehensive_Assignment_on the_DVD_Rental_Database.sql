SELECT 
	UPPER(se_film.title) AS upper_title
FROM public.film AS se_film;

SELECT 
	ROUND(se_film.length / 60.0, 2) AS length_in_hours
FROM public.film AS se_film;

SELECT 
	EXTRACT( YEAR FROM se_actor.last_update) AS update_year
FROM public.actor AS se_actor;

SELECT 
	COUNT(se_fim.film_id) AS total_films
FROM public.film AS se_fim;

SELECT 
	AVG(se_film.rental_rate) AS average_rental_rate
FROM public.film AS se_film;

SELECT 
	MAX(se_film.length) AS highest_length, 
	MIN(se_film.length) AS lowest_lengt
FROM film AS se_film;

SELECT
	se_category.name AS category_name,
	COUNT(se_film_category.film_id) AS total_films
FROM public.category AS se_category
LEFT JOIN public.film_category AS se_film_category
	ON se_film_category.category_id = se_category.category_id
GROUP BY 
	se_category.name;

SELECT 
	se_film.title AS film_title,
	se_film.length AS film_length,
	RANK() OVER(ORDER BY se_film.length DESC) AS length_rank
FROM public.film AS se_film;

SELECT
	se_film.film_id AS film_id,
    se_film.title AS film_title,
	se_film.length AS film_length,
    SUM(se_film.length) OVER (ORDER BY se_film.film_id) AS cumulative_length_sum
FROM film AS se_film;

SELECT 
	se_film.film_id AS film_id,
    se_film.title AS film_title,
	LEAD(se_film.title) OVER (ORDER BY se_film.title) AS next_film_title
FROM film AS se_film;

SELECT
	se_film.title AS film_title,
	se_film.length AS film_length,
    CASE
        WHEN se_film.length < 60 THEN 'Short'
        WHEN se_film.length >= 60 AND se_film.length <= 120 THEN 'Medium'
        ELSE 'Long'
    END AS length_classification
FROM public.film AS se_film;

SELECT
    se_payment.payment_id,
    COALESCE(se_payment.amount, (SELECT 
					  	AVG(se_payment.amount) 
					  FROM payment AS se_payment)) AS adjusted_amount
FROM public.payment AS se_payment;

CREATE OR REPLACE FUNCTION public.film_category(film_title TEXT)
RETURNS TEXT AS 
$$
DECLARE 
    category_name TEXT;
BEGIN 
    SELECT
        se_category.name
    INTO category_name
    FROM public.film AS se_film
    INNER JOIN public.film_category AS se_film_category
        ON se_film.film_id = se_film_category.film_id
    INNER JOIN public.category AS se_category
        ON se_category.category_id = se_film_category.category_id
    WHERE se_film.title = film_title;
    
    RETURN category_name;
END;
$$
LANGUAGE plpgsql;

SELECT * 
FROM public.film_category('Chamber Italian');

-- function takes a film title as an argument and returns the total number of times the film has been rented.
CREATE OR REPLACE FUNCTION total_rentals(film_title TEXT)
RETURNS INTEGER AS $$
DECLARE
    rental_count INTEGER;
BEGIN
    SELECT 
		COUNT(se_renatal.rental_id) 
	INTO rental_count
    FROM rental AS se_renatal
    INNER JOIN inventory AS se_inventory
		ON se_renatal.inventory_id = se_inventory.inventory_id
    INNER JOIN film AS se_film 
		ON se_inventory.film_id = se_film.film_id
    WHERE se_film.title = film_title;
    
    RETURN rental_count;
END;
$$ LANGUAGE plpgsql;

SELECT * 
FROM public.total_rentals('Chamber Italian')

-- function takes a customer ID as input and returns a JSON containing the customer's name, total rentals, and total amount spent.
CREATE OR REPLACE FUNCTION public.customer_stats(customer_id_input INTEGER)
RETURNS JSONB AS $$
DECLARE
    customer_info JSONB;
BEGIN
    SELECT jsonb_build_object(
        'customer_name', CONCAT(se_customer.first_name, ' ', se_customer.last_name),
        'total_rentals', COUNT(se_rental.rental_id),
        'total_amount_spent', SUM(se_payment.amount)
    ) 
    INTO customer_info
    FROM public.customer AS se_customer
    LEFT JOIN public.rental AS se_rental 
        ON se_customer.customer_id = se_rental.customer_id
    LEFT JOIN public.payment AS se_payment 
        ON se_rental.rental_id = se_payment.rental_id
    WHERE se_customer.customer_id = customer_id_input
    GROUP BY 
		CONCAT(se_customer.first_name, ' ', se_customer.last_name);
    
    RETURN customer_info;
END;
$$ LANGUAGE plpgsql;


--524
SELECT * 
FROM public.customer_stats(customer_id_input:=524)


