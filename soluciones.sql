USE hobbies_nm_db;


SHOW FUNCTION STATUS WHERE Name LIKE 'f_get%';
SHOW PROCEDURE STATUS WHERE Name LIKE 'f_get%';

DELIMITER //
-- f_get_hobby_id que devuelva el id de una afición a partir de su nombre
CREATE OR REPLACE FUNCTION f_get_hobby_id(p_hobby_name VARCHAR(128))

RETURNS INT
READS SQL data
BEGIN 
 
	DECLARE v_hobby_id INT;
	SELECT h.hobby_id INTO v_hobby_id
	FROM hobbies h
	WHERE h.hobby_name = p_hobby_name;
	RETURN v_hobby_id;
END //
DELIMITER ;


SELECT f_get_hobby_id('Cine');
		



CREATE OR REPLACE TABLE p_add_hobby_to_user(
	IN p_user_id INT,
	IN p_hobby_name VARCHAR(128)
)
BEGIN 
	DECLARE v_hobby_id INT;
	SET v_hobby_id INT= f_get_hobby_id(p_hobby_name);
	IF EXISTS (
		SELECT *
		FROM users_hobbies uh
		WHERE uh.user_id = p_user_id
			AND uh.hobby_id = v_hobby_id
			) THEN 
				SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'RN03:EL usuario ya tiene esa aficion';
	END IF;
	
	IF v_hobby_id IS NULL THEN 
		INSERT INTO hobbies (hobby_name) VALUES (p_hobby_name);
		SET v_hobby_id = LAST_INSERT_ID();
	END IF;
	
	INSERT INTO users_hobbies(user_id, hobby_id) VALUES (p_user_id, v_hobby_id);
END //



-- transaction1 -------------
CREATE OR REPLACE procedures p_add_hobby_to_user_tx(
	IN p_user_id INT,
	IN p_hobby_name VARCHAR(128)
)
BEGIN 
	DECLARE exit handler FOR SQLEXCEPTION 
	begin
		ROLLBACK;
		RESIGNAL;
	END;
	START TRANSACTION;
		CALL p_add_hobby_to_user(p_user_id, p_hobby_name);
	COMMIT;
END //





-- f_hobby_users que devuelva cuántos usuarios tienen una afición y úsala para comprobar el resultado de la fusión.
CREATE OR REPLACE FUNCTION f_hobby_users(p_hobby_id INT)
RETURN INT 
READS SQL DATA
BEGIN 
	DECLARE v_users INT;
	
	SELECT COUNT(*) INTO v_users
	FROM users_hobbies uh
	WHERE uh.hobby_id=p_hobby_id;
	RETURN v_users;
END//



-- merging
CREATE OR REPLACE PROCEDURE p_merge_hobbies(
	IN p_old_hobby_id INT,
	IN p_new_hobby_id INT
)
BEGIN IF p_old_hobby_id = p_new_hibbt_id THEN 
	SIGNAL SQL state '45000'
		SET MESSAGE_TEXT = 'RI02: NO se puede fusionar una aficion consigo misma';
	END IF;
	IF NOT EXISTS (SELECT *FROM hobbies h WHERE h.hobby_id = p_old_hobby_id)
		OR NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_new_hobby_id) THEN 
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'RI02: las dos aficiones deben estar en el catalogo';
	END IF;
	DELETE FROM users_hobbies
	WHERE hobby_id = p_hobby_id
		AND user_id IN (
			SELECT uh.user_id
			FROM users_hobbies uh
			WHERE uh.hobby_id = p_new_hobby_id
		);
	UPDATE users_hobbies
	SET hobby_id = p_new_hobby_id
	WHERE hobby_id = p_old_hobby_id;
	DELETE FROM hobbies
	WHERE hobby_id = p_old_hobbu_id;
END //

CREATE OR REPLACE p_merge_hobbies_tx(
	IN p_old_hobby_id INT,
	IN p_new_hobby_id INT
)
BEGIN 
	DECLARE exit handler FOR SQLEXCEPTION 
	begin
		ROLLBACK;
		RESIGNAL;
	END;
	START TRANSACTION;
		CALL p_add_hobby_to_user(p_old_hobby_id, p_new_hobby_id);
	COMMIT;
END //

	
DELIMITER ;

CALL p_populate();
-- test 2
SELECT uh.user_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;

-- prueba trans1
SELECT uh.user_id, h.hobby_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 3;

