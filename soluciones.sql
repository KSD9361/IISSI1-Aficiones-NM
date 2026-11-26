USE hobbies_nm_db;



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


-- SELECT f_get_hobby_id('Cine');

DELIMITER //		
CREATE OR REPLACE PROCEDURE p_add_hobby_to_user(
	IN p_user_id INT,
	IN p_hobby_name VARCHAR(128)
)
BEGIN 
	DECLARE v_hobby_id INT;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;
	START TRANSACTION;
	SET v_hobby_id = f_get_hobby_id(p_hobby_name);
	IF EXISTS (SELECT * FROM users_hobbies uh 
				WHERE uh.user_id = p_user_id AND uh.hobby_id = v_hobby_id ) THEN 
		SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'RN03:The users has this hobby';
	END IF;
	
	IF v_hobby_id IS NULL THEN 
		INSERT INTO hobbies (hobby_name) VALUES (p_hobby_name);
		SET v_hobby_id = LAST_INSERT_ID();
   END if;
   
   INSERT INTO users_hobbies(user_id, hobby_id) VALUES (p_user_id, v_hobby_id);
   COMMIT;
END// 
DELIMITER ;

SELECT uh.user_id, h.hobby_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 3;


DELIMITER //
CREATE OR REPLACE PROCEDURE p_merge_hobbies(
	IN p_ohb_id INT,
	IN p_nhb_id INT 
) 
BEGIN
	DECLARE exit handler FOR SQLEXCEPTION 
	begin
		ROLLBACK;
		RESIGNAL;
	END;
	START TRANSACTION;
	 
	if NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_ohb_id)
		OR NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_nhb_id) then 
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'Una de las aficiones no existe';
	end if;			
	
	DELETE FROM users_hobbies 
	WHERE hobby_id = p_ohb_id 
	AND user_id IN (
			SELECT uh.user_id
			FROM users_hobbies uh
			WHERE uh.hobby_id = p_nhb_id
		);
	UPDATE users_hobbies
	SET hobby_id = p_nhb_id
	WHERE hobby_id = p_ohb_id;
	 
	DELETE FROM hobbies 
	WHERE hobby_id = p_ohb_id;
	COMMIT;
END //
DELIMITER ;



