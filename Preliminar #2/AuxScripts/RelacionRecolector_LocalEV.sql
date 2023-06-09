Select rt.nombre as Productor, r.ev_id as LocalEV, SUM(r.cantidad) as VolumenRecolectado
from recoleccion r
JOIN recolectores rt ON rt.recolector_id = r.recolector_id
GROUP BY
rt.nombre,
r.ev_id
ORDER BY
r.ev_id
