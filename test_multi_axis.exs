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
  IO.puts("✅ dual_axis/3 works! Generated spec with #{length(spec["layer"])} layers")
  IO.puts("   - Has resolve config: #{Map.has_key?(spec, "resolve")}")
  IO.puts("   - Right axis orient: #{get_in(spec, ["layer", 1, "encoding", "y", "axis", "orient"])}")
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
  IO.puts("✅ multi_axis/2 works! Generated spec with #{length(spec["layer"])} layers")
  IO.puts("   - Has independent Y scales: #{get_in(spec, ["resolve", "scale", "y"]) == "independent"}")
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
  IO.puts("✅ add_layer/2 works! Generated spec with #{length(spec["layer"])} layers")
rescue
  error ->
    IO.puts("❌ add_layer/2 failed: #{inspect(error)}")
end

# Test 4: facet_by function
IO.puts("\n4. Testing facet_by/2...")

try do
  faceted_chart = Vl.new()
  |> Vl.data_from_values(data ++ Enum.map(data, &Map.put(&1, "run_id", "run_2")))
  |> Vl.mark(:line)
  |> Vl.encode_field(:x, "x")
  |> Vl.encode_field(:y, "temp")
  |> Vl.facet_by("run_id", columns: 2)
  
  spec = Vl.to_spec(faceted_chart)
  IO.puts("✅ facet_by/2 works! Generated faceted spec")
  IO.puts("   - Facet field: #{get_in(spec, ["facet", "field"])}")
  IO.puts("   - Columns: #{get_in(spec, ["facet", "columns"])}")
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
  IO.puts("✅ fermentation_temp_ph_chart/1 works!")
  IO.puts("   - Temperature field: #{get_in(spec, ["layer", 0, "encoding", "y", "field"])}")
  IO.puts("   - pH field: #{get_in(spec, ["layer", 1, "encoding", "y", "field"])}")
rescue
  error ->
    IO.puts("❌ fermentation_temp_ph_chart/1 failed: #{inspect(error)}")
end

IO.puts("\n🎉 Multi-axis functionality testing complete!")
