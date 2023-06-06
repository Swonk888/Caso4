select le.ev_id, c.nombre as Ciudad, le.telefono
from local_ev le
JOIN ubicaciones u ON u.ubicacion_id = le.ubicacion_id
JOIN paises p ON p.pais_id = u.pais_id
JOIN estado e ON e.estado_id = p.estado_id
JOIN ciudades c ON c.ciudad_id = e.ciudad_id
ORDER BY
le.ev_id