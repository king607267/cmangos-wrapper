-- change name,address,port if necessary

DELETE FROM realmlist WHERE id=1;

INSERT INTO realmlist (id, name, address, port, icon, realmflags, timezone, allowedSecurityLevel)
VALUES ('1', 'MaNGOS', '127.0.0.1', '8085', '1', '0', '1', '0');