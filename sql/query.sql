SELECT jsonb_build_object(
    'type',     'FeatureCollection',
    'features', jsonb_agg(feature)
)
FROM (
  SELECT jsonb_build_object(
    'type',       'Feature',
    'id',         "MESH_CODE",
    'geometry',   ST_AsGeoJSON(geom)::jsonb,
    'properties', to_jsonb(row) - "MESH_CODE" - 'geom'
  ) AS feature
  FROM (SELECT * FROM mesh4 where "MESH_CODE" like '5339445%') row) features;
