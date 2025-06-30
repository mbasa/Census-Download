CREATE OR REPLACE FUNCTION generate_japan_mesh_polygon(mesh_code_str TEXT)
RETURNS geometry(Polygon, 4326) AS $$
DECLARE
    p_val INTEGER;
    q_val INTEGER;
    r_val INTEGER;
    s_val INTEGER;
    t_val INTEGER;
    u_val INTEGER;
    v_val INTEGER;

    lat_base_1 DOUBLE PRECISION;
    lon_base_1 DOUBLE PRECISION;
    lat_add_2 DOUBLE PRECISION;
    lon_add_2 DOUBLE PRECISION;
    lat_add_3 DOUBLE PRECISION;
    lon_add_3 DOUBLE PRECISION;
    lat_half_grid_offset DOUBLE PRECISION;
    lon_half_grid_offset DOUBLE PRECISION;

    sw_latitude DOUBLE PRECISION;
    sw_longitude DOUBLE PRECISION;
    delta_lat DOUBLE PRECISION;
    delta_lon DOUBLE PRECISION;

    ne_latitude DOUBLE PRECISION;
    ne_longitude DOUBLE PRECISION;
    nw_latitude DOUBLE PRECISION;
    nw_longitude DOUBLE PRECISION;
    se_latitude DOUBLE PRECISION;
    se_longitude DOUBLE PRECISION;

    polygon_wkt TEXT;
BEGIN
    -- Validate mesh code length
    IF LENGTH(mesh_code_str) != 9 THEN
        RAISE EXCEPTION 'Invalid mesh code length. Expected 9 digits, got %', LENGTH(mesh_code_str);
    END IF;

    -- Extract components from the mesh code string
    p_val := CAST(SUBSTRING(mesh_code_str FROM 1 FOR 2) AS INTEGER);
    q_val := CAST(SUBSTRING(mesh_code_str FROM 3 FOR 2) AS INTEGER);
    r_val := CAST(SUBSTRING(mesh_code_str FROM 5 FOR 1) AS INTEGER);
    s_val := CAST(SUBSTRING(mesh_code_str FROM 6 FOR 1) AS INTEGER);
    t_val := CAST(SUBSTRING(mesh_code_str FROM 7 FOR 1) AS INTEGER);
    u_val := CAST(SUBSTRING(mesh_code_str FROM 8 FOR 1) AS INTEGER);
    v_val := CAST(SUBSTRING(mesh_code_str FROM 9 FOR 1) AS INTEGER);

    -- 1. Primary Mesh Base (south-west corner)
    lat_base_1 := p_val * (2.0/3.0);
    lon_base_1 := q_val + 100.0;

    -- 2. Secondary Mesh Contribution (south-west corner of secondary mesh)
    lat_add_2 := r_val * (5.0/60.0);
    lon_add_2 := s_val * (7.5/60.0);

    -- 3. Tertiary Mesh Contribution (south-west corner of tertiary mesh)
    lat_add_3 := t_val * (30.0/3600.0);
    lon_add_3 := u_val * (45.0/3600.0);

    -- 4. Half Grid Contribution (offset from tertiary mesh bottom-left corner to half-grid's SW corner)
    lat_half_grid_offset := 0.0;
    lon_half_grid_offset := 0.0;

    IF v_val = 1 THEN -- SW quadrant of tertiary mesh
        lat_half_grid_offset := 0.0;
        lon_half_grid_offset := 0.0;
    ELSIF v_val = 2 THEN -- SE quadrant of tertiary mesh
        lat_half_grid_offset := 0.0;
        lon_half_grid_offset := 22.5/3600.0;
    ELSIF v_val = 3 THEN -- NW quadrant of tertiary mesh
        lat_half_grid_offset := 15.0/3600.0;
        lon_half_grid_offset := 0.0;
    ELSIF v_val = 4 THEN -- NE quadrant of tertiary mesh
        lat_half_grid_offset := 15.0/3600.0;
        lon_half_grid_offset := 22.5/3600.0;
    ELSE
        RAISE EXCEPTION 'Invalid Half Grid (V) digit: %. Must be 1, 2, 3, or 4.', v_val;
    END IF;

    -- Southwest corner of the half-grid square
    sw_latitude := lat_base_1 + lat_add_2 + lat_add_3 + lat_half_grid_offset;
    sw_longitude := lon_base_1 + lon_add_2 + lon_add_3 + lon_half_grid_offset;

    -- Dimensions of a half-grid square
    delta_lat := 15.0 / 3600.0;  -- 15 seconds in degrees
    delta_lon := 22.5 / 3600.0; -- 22.5 seconds in degrees

    -- Calculate all four corners
    nw_latitude := sw_latitude + delta_lat;
    nw_longitude := sw_longitude;

    se_latitude := sw_latitude;
    se_longitude := sw_longitude + delta_lon;

    ne_latitude := sw_latitude + delta_lat;
    ne_longitude := sw_longitude + delta_lon;

    -- Construct the WKT (Well-Known Text) for the polygon
    -- Order of points for a polygon: (lon lat), closing the loop
    polygon_wkt := FORMAT('POLYGON((%s %s, %s %s, %s %s, %s %s, %s %s))',
                          sw_longitude, sw_latitude,
                          se_longitude, se_latitude,
                          ne_longitude, ne_latitude,
                          nw_longitude, nw_latitude,
                          sw_longitude, sw_latitude);

    -- Return the PostGIS geometry object
    RETURN ST_GeomFromText(polygon_wkt, 4326);
END;
$$ LANGUAGE plpgsql;
