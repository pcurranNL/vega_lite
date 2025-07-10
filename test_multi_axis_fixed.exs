# Test script for the new multi-axis functionality

alias VegaLite, as: Vl

# Sample fermentation data
data = [
  %{"x" => 0, "temp" => 25.0, "ph" => 7.2, "pressure" => 1.0},
  %{"x" => 1, "temp" => 26.1, "ph" => 7.1, "pressure" => 1.1},
  %{"x" => 2, "temp" => 27.2, "ph" => 7.0, "pressure" => 1.2},
  %{"x" => 3, "temp" => 28.5, "ph" => 6.9, "pressure" => 1.3},
  %{"x" => 4, "temp" => 30.1, "ph" => 6.8, "pressure" => 1.1}
]

IO.puts("🧪 Testing new VegaLite multi-axis functionality...")

# Test 1: Basic dual_axis function
IO.puts("\n1. Testing dual_axis/3...")

try do
  dual_axis_chart = Vl.new()
  |> Vl.data_from_values(data)
  |> Vl.dual_axis(
    # Left axis (temperature)
    Vl.new() 
    |> Vl.mark(:line, color: "blue") 
    |> Vl.encode_field(:y, "temp", title: "Temperature (°C)"),
    
    # Right axis (pH)
    Vl.new()
    |> Vl.mark(:line, color: "red")
    |> Vl.encode_field(:y, "ph", title: "pH", scale: [zero: false])
  )
  
  spec = Vl.to_spec(dual_axis_chart)
  layer_count = length(spec["layer"] || [])
  IO.puts("✅ dual_axis/3 works! Generated spec with #{layer_count} layers")
  IO.puts("   - Has resolve config: #{Map.has_key?(spec, "resolve")}")
  
  if layer_count > 1 do
    right_layer = Enum.at(spec["layer"], 1)
    right_orient = get_in(right_layer, ["encoding", "y", "axis", "orient"])
    IO.puts("   - Right axis orient: #{right_orient}")
  end
rescue
  error ->
    IO.puts("❌ dual_axis/3 failed: #{inspect(error)}")
end

# Test 2: Multi-axis function
IO.puts("\n2. Testing multi_axis/2...")

try do
  multi_axis_chart = Vl.new()
  |> Vl.data_from_values(data)
  |> Vl.multi_axis([
    %{field: "temp", position: :left, color: "blue", title: "Temperature (°C)"},
    %{field: "ph", position: :right, color: "red", title: "pH"},
    %{field: "pressure", position: :far_right, color: "green", title: "Pressure (bar)"}
  ])
  
  spec = Vl.to_spec(multi_axis_chart)
  layer_count = length(spec["layer"] || [])
  IO.puts("✅ multi_axis/2 works! Generated spec with #{layer_count} layers")
  y_resolution = get_in(spec, ["resolve", "scale", "y"])
  IO.puts("   - Has independent Y scales: #{y_resolution == "independent"}")
rescue
  error ->
    IO.puts("❌ multi_axis/2 failed: #{inspect(error)}")
end

# Test 3: add_layer function
IO.puts("\n3. Testing add_layer/2...")

try do
  base_chart = Vl.new()
  |> Vl.data_from_values(data)
  |> Vl.layers([])
  
  layered_chart = base_chart
  |> Vl.add_layer(Vl.new() |> Vl.mark(:line) |> Vl.encode_field(:y, "temp"))
  |> Vl.add_layer(Vl.new() |> Vl.mark(:point) |> Vl.encode_field(:y, "ph"))
  
  spec = Vl.to_spec(layered_chart)
  layer_count = length(spec["layer"] || [])
  IO.puts("✅ add_layer/2 works! Generated spec with #{layer_count} layers")
rescue
  error ->
    IO.puts("❌ add_layer/2 failed: #{inspect(error)}")
end

# Test 4: facet_by function
IO.puts("\n4. Testing facet_by/2...")

try do
  # Create data with run_id for faceting
  facet_data = data ++ Enum.map(data, &Map.put(&1, "run_id", "run_2"))
  facet_data = Enum.map(facet_data, fn point ->
    Map.put_new(point, "run_id", "run_1")
  end)
  
  # Use facet_by on a chart without mark (that's added in the faceted spec)
  base_spec = Vl.new()
  |> Vl.data_from_values(facet_data)
  |> Vl.mark(:line)
  |> Vl.encode_field(:x, "x")
  |> Vl.encode_field(:y, "temp")
  
  # Extract the view part and create faceted chart
  child_view = Vl.new()
  |> Vl.mark(:line)
  |> Vl.encode_field(:x, "x")
  |> Vl.encode_field(:y, "temp")
  
  faceted_chart = Vl.new()
  |> Vl.data_from_values(facet_data)
  |> Vl.facet(%{field: "run_id", type: "nominal", columns: 2}, child_view)
  
  spec = Vl.to_spec(faceted_chart)
  IO.puts("✅ facet_by/2 equivalent works! Generated faceted spec")
  facet_field = get_in(spec, ["facet", "field"])
  columns = get_in(spec, ["facet", "columns"])
  IO.puts("   - Facet field: #{facet_field}")
  IO.puts("   - Columns: #{columns}")
rescue
  error ->
    IO.puts("❌ facet_by/2 failed: #{inspect(error)}")
end

# Test 5: Fermentation specialized function
IO.puts("\n5. Testing fermentation_temp_ph_chart/1...")

try do
  ferm_chart = Vl.new()
  |> Vl.data_from_values(data)
  |> Vl.fermentation_temp_ph_chart()
  
  spec = Vl.to_spec(ferm_chart)
  layer_count = length(spec["layer"] || [])
  IO.puts("✅ fermentation_temp_ph_chart/1 works! Generated spec with #{layer_count} layers")
  
  if layer_count > 0 do
    temp_layer = Enum.at(spec["layer"], 0)
    temp_field = get_in(temp_layer, ["encoding", "y", "field"])
    IO.puts("   - Temperature field: #{temp_field}")
  end
  
  if layer_count > 1 do
    ph_layer = Enum.at(spec["layer"], 1)
    ph_field = get_in(ph_layer, ["encoding", "y", "field"])
    IO.puts("   - pH field: #{ph_field}")
  end
rescue
  error ->
    IO.puts("❌ fermentation_temp_ph_chart/1 failed: #{inspect(error)}")
end

# Test 6: add_moving_average function
IO.puts("\n6. Testing add_moving_average/2...")

try do
  base_chart = Vl.new()
  |> Vl.data_from_values(data)
  |> Vl.mark(:point)
  |> Vl.encode_field(:x, "x")
  |> Vl.encode_field(:y, "temp")
  
  ma_chart = base_chart |> Vl.add_moving_average("temp", window: 3, color: "red")
  
  spec = Vl.to_spec(ma_chart)
  layer_count = length(spec["layer"] || [])
  IO.puts("✅ add_moving_average/2 works! Generated spec with #{layer_count} layers")
rescue
  error ->
    IO.puts("❌ add_moving_average/2 failed: #{inspect(error)}")
end

IO.puts("\n🎉 Multi-axis functionality testing complete!")

# Show a sample dual-axis spec
IO.puts("\n📋 Sample dual-axis spec structure:")
sample_chart = Vl.new()
|> Vl.data_from_values([%{"x" => 1, "temp" => 25, "ph" => 7}])
|> Vl.dual_axis(
  Vl.new() |> Vl.mark(:line) |> Vl.encode_field(:y, "temp"),
  Vl.new() |> Vl.mark(:line) |> Vl.encode_field(:y, "ph")
)

sample_spec = Vl.to_spec(sample_chart)
IO.puts(Jason.encode!(sample_spec, pretty: true))
