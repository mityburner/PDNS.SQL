CREATE TABLE `domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `master` varchar(128) DEFAULT NULL,
  `last_check` int(11) DEFAULT NULL,
  `type` varchar(6) NOT NULL,
  `notified_serial` int(11) DEFAULT NULL,
  `account` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_index` (`name`)
) Engine=InnoDB;

CREATE TABLE `records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain_id` int(11) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(6) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `ttl` int(11) DEFAULT NULL,
  `prio` int(11) DEFAULT NULL,
  `change_date` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`,`type`,`content`),
  KEY `rec_name_index` (`name`),
  KEY `nametype_index` (`name`,`type`),
  KEY `domain_id` (`domain_id`),
  FOREIGN KEY (`domain_id`) REFERENCES `domains` (`id`)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TRIGGER after_insert_domains;
DELIMITER $$
CREATE TRIGGER after_insert_domains
AFTER INSERT ON domains
FOR EACH ROW
BEGIN
    insert into records values(0,new.id,new.name,'NS','ns.zhuoyue.com',3600,0,UNIX_TIMESTAMP());
    insert into records values(0,new.id,new.name,'NS','ns2.zhuoyue.com',3600,0,UNIX_TIMESTAMP());
    insert into records values(0,new.id,new.name,'SOA','ns.zhuoyue.com root@zhuoyue.com 0 28800 7200 604800 3600',3600,0,UNIX_TIMESTAMP());
END $$
DELIMITER ;

DROP TRIGGER before_insert_records;
DELIMITER $$
CREATE TRIGGER before_insert_records
BEFORE INSERT ON records
FOR EACH ROW
BEGIN
    DECLARE old_domain_id int(11);
    IF new.type='SOA' OR new.type='NS' THEN
        select domain_id into old_domain_id from records where domain_id=new.domain_id and type='SOA';
        IF old_domain_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'deny insert SOA|NS record';
        END IF;
    END IF;
END $$
DELIMITER ;

DROP TRIGGER before_update_records;
DELIMITER $$
CREATE TRIGGER before_update_records
BEFORE UPDATE ON records
FOR EACH ROW
BEGIN
    IF old.type='SOA' AND (old.domain_id!=new.domain_id OR old.name!=new.name OR old.type!=new.type)
    OR old.type='NS'  AND (old.domain_id!=new.domain_id OR old.name!=new.name OR old.type!=new.type OR old.content!=new.content) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'deny update SOA|NS record';
    END IF;
END $$
DELIMITER ;

DROP TRIGGER before_delete_records;
DELIMITER $$
CREATE TRIGGER before_delete_records
BEFORE DELETE ON records
FOR EACH ROW
BEGIN
    DECLARE old_id int(11);
    IF old.type='SOA' OR old.type='NS' THEN
        select id into old_id from domains where name=old.name;
        IF old_id THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'deny delete SOA|NS record';
        END IF;
    END IF;
END $$
DELIMITER ;
