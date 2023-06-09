
Select c.nombre as Ciudad, r.ev_id as LocalEV, SUM(r.cantidad) as VolumenRecolectado
from recoleccion r
JOIN ubicaciones u ON u.ubicacion_id = r.ubicacion_id
JOIN paises p ON p.pais_id = u.pais_id
JOIN estado e ON e.estado_id = p.estado_id
JOIN ciudades c ON c.ciudad_id = e.ciudad_id
GROUP BY
c.nombre,
r.ev_id
ORDER BY
r.ev_id
