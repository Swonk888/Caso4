
Select pr.nombre as Productor, r.ev_id as LocalEV, SUM(r.cantidad) as VolumenRecolectado
from recoleccion r
JOIN productores_residuos pr ON pr.productor_id = r.productor_id
GROUP BY
pr.nombre,
r.ev_id
ORDER BY
r.ev_id