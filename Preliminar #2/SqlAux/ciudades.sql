
Select c.ciudad_id, c.nombre as Nombre
from ubicaciones u
JOIN paises p ON p.pais_id = u.pais_id
JOIN estado e ON e.estado_id = p.estado_id
JOIN ciudades c ON c.ciudad_id = e.ciudad_id
ORDER BY
c.ciudad_id