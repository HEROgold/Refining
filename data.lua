local recipes = {}

local liquids = {}
local crystals = {}
local chunks = {}
local dusts = {}
local compounds = {}


-- Define recipe categories
recipe_categories = {
    {
        type = "recipe-category",
        name = "liquifying-ore",
    },
    {
        type = "recipe-category",
        name = "crystallizing-liquid",
    },
    {
        type = "recipe-category",
        name = "crystallizing-ore",
    },
    {
        type = "recipe-category",
        name = "chunkifying-crystal",
    },
    {
        type = "recipe-category",
        name = "chunkifying-ore",
    },
    {
        type = "recipe-category",
        name = "dustifying-chunk",
    },
    {
        type = "recipe-category",
        name = "dustifying-ore",
    },
    {
        type = "recipe-category",
        name = "compounding-dust",
    },
    {
        type = "recipe-category",
        name = "compounding-ore",
    },
}

-- HELPERS

---@param ref_item data.ItemPrototype
local function get_liquid_name(ref_item)
    return ref_item.name .. "-liquid"
end

---@param ref_item data.ItemPrototype
local function get_crysalized_name(ref_item)
    return "crystallized-" .. ref_item.name
end

---@param ref_item data.ItemPrototype
local function get_chunk_name(ref_item)
    return ref_item.name .. "-chunk"
end

---@param ref_item data.ItemPrototype
local function get_dust_name(ref_item)
    return ref_item.name .. "-dust"
end

---@param ref_item data.ItemPrototype
local function get_compound_name(ref_item)
    return ref_item.name .. "-compound"
end


---@param ref_item data.ItemPrototype
local function get_smelting_results(ref_item)
    local item_name = ref_item.name
    local smelting_results = {}

    for name, recipe in pairs(data.raw.recipe) do
        -- Check if the recipe is for smelting the ore
        if (
            recipe.category == "smelting"
            and recipe.ingredients ~= nil
            and #recipe.ingredients > 0
        ) then
            for _, ingredient in pairs(recipe.ingredients) do
                if ingredient.name == item_name then
                    return recipe.results
                end
            end
        end
    end
end

-- END HELPERS

---@param ref_item data.ItemPrototype
local function add_fluid(ref_item)
    ---@type data.FluidPrototype
    local liq = table.deepcopy(data.raw["fluid"]["water"])
    liq.name = get_liquid_name(ref_item)

    table.insert(liquids, liq)
end

---@param ref_item data.ItemPrototype
local function add_crystal(ref_item)
    ---@type data.ItemPrototype
    local item = table.deepcopy(ref_item)
    item.name = get_crysalized_name(ref_item)
    table.insert(crystals, item)
end

---@param ref_item data.ItemPrototype
local function add_chunk(ref_item)
    ---@type data.ItemPrototype
    local item = table.deepcopy(ref_item)
    item.name = get_chunk_name(ref_item)
    table.insert(chunks, item)
end

---@param ref_item data.ItemPrototype
local function add_dust(ref_item)
    ---@type data.ItemPrototype
    local item = table.deepcopy(ref_item)
    item.name = get_dust_name(ref_item)
    table.insert(dusts, item)
end

---@param ref_item data.ItemPrototype
local function add_compound(ref_item)
    ---@type data.ItemPrototype
    local item = table.deepcopy(ref_item)
    item.name = get_compound_name(ref_item)
    table.insert(compounds, item)
end

local function add_buildings()
    local item = data.raw["item"]["stone-furnace"]

    local liquifier_item = table.deepcopy(item)
    local crystallizer_item = table.deepcopy(item)
    local chunkifier_item = table.deepcopy(item)
    local dustifier_item = table.deepcopy(item)
    local compounder_item = table.deepcopy(item)

    local furnace = table.deepcopy(data.raw["furnace"]["stone-furnace"])

    ---@type table<data.FurnacePrototype>
    buildings = {}

    local liquifier = table.deepcopy(furnace)
    local crystallizer = table.deepcopy(furnace)
    local chunkifier = table.deepcopy(furnace)
    local dustifier = table.deepcopy(furnace)
    local compounder = table.deepcopy(furnace)

    -- set names
    liquifier.name = "liquifier"
    crystallizer.name = "crystallizer"
    chunkifier.name = "chunkifier"
    dustifier.name = "dustifier"
    compounder.name = "compounder"

    liquifier_item.name = "liquifier"
    crystallizer_item.name = "crystallizer"
    chunkifier_item.name = "chunkifier"
    dustifier_item.name = "dustifier"

    -- set crafting categories
    liquifier.crafting_categories = {"liquifying-ore"}
    crystallizer.crafting_categories = {"crystallizing-liquid", "crystallizing-ore"}
    chunkifier.crafting_categories = {"chunkifying-crystal", "chunkifying-ore"}
    dustifier.crafting_categories = {"dustifying-chunk", "dustifying-ore"}
    compounder.crafting_categories = {"compounding-dust", "compounding-ore"}

    -- set item place results
    liquifier_item.place_result = "liquifier"
    crystallizer_item.place_result = "crystallizer"
    chunkifier_item.place_result = "chunkifier"
    dustifier_item.place_result = "dustifier"
    compounder_item.place_result = "compounder"

    -- create subgroup
    data:extend({
        {
            type = "item-subgroup",
            name = "refining",
            group = "production",
            order = "a"
        }
    })

    -- set item subgroups
    liquifier_item.subgroup = "refining"
    crystallizer_item.subgroup = "refining"
    chunkifier_item.subgroup = "refining"
    dustifier_item.subgroup = "refining"
    compounder_item.subgroup = "refining"

    -- set item order
    liquifier_item.order = "a"
    crystallizer_item.order = "b"
    chunkifier_item.order = "c"
    dustifier_item.order = "d"
    compounder_item.order = "e"

    table.insert(buildings, liquifier_item)
    table.insert(buildings, crystallizer_item)
    table.insert(buildings, chunkifier_item)
    table.insert(buildings, dustifier_item)
    table.insert(buildings, compounder_item)

    table.insert(buildings, liquifier)
    table.insert(buildings, crystallizer)
    table.insert(buildings, chunkifier)
    table.insert(buildings, dustifier)
    table.insert(buildings, compounder)
end


-- RECIPE CHAINS

-- Ore > Liquid
-- Ore > Crystal
-- Ore > Chunk
-- Ore > Dust
-- Ore > Compound

-- Liquid > Crystal
-- Crystal > Chunk
-- Chunk > Dust
-- Dust > Compound

-- Compound > Plate


---@param ref_item data.ItemPrototype
local function ore_to_liquid_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "ore-to-liquid-" .. ref_item.name,
        category = "liquifying-ore",
        ingredients = {
            {
                type = "item",
                name = ref_item.name,
                amount = 1
            }
        },
        results = {
            {type = "fluid", name = get_liquid_name(ref_item), amount = 10}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function ore_to_crystal_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "ore-to-crystal-" .. ref_item.name,
        category = "crystallizing-ore",
        ingredients = {
            {
                type = "item",
                name = ref_item.name,
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_crysalized_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function ore_to_chunk_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "ore-to-chunk-" .. ref_item.name,
        category = "chunkifying-ore",
        ingredients = {
            {
                type = "item",
                name = ref_item.name,
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_chunk_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function ore_to_dust_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "ore-to-dust-" .. ref_item.name,
        category = "dustifying-ore",
        ingredients = {
            {
                type = "item",
                name = ref_item.name,
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_dust_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function ore_to_compound_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "ore-to-compound-" .. ref_item.name,
        category = "compounding-ore",
        ingredients = {
            {
                type = "item",
                name = ref_item.name,
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_compound_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function compound_to_plate_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "compound-to-plate-" .. ref_item.name,
        category = "smelting",
        ingredients = {
            {
                type = "item",
                name = get_compound_name(ref_item),
                amount = 1
            }
        },
        results = get_smelting_results(ref_item) or {{type = "item", name = "iron-plate", amount = 9}},
        subgroup = ref_item.subgroup,
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function add_ore_recipes(ref_item)
    ore_to_liquid_recipe(ref_item)
    ore_to_crystal_recipe(ref_item)
    ore_to_chunk_recipe(ref_item)
    ore_to_dust_recipe(ref_item)
    ore_to_compound_recipe(ref_item)
end

---@param ref_item data.ItemPrototype
local function liquid_to_crystal_recipe(ref_item)

    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "liquid-to-crystal-" .. ref_item.name,
        category = "crystallizing-liquid",
        ingredients = {
            {
                type = "fluid",
                name = get_liquid_name(ref_item),
                amount = 10
            }
        },
        results = {
            {type = "item", name = get_crysalized_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function crystal_to_chunk_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "crystal-to-chunk-" .. ref_item.name,
        category = "chunkifying-crystal",
        ingredients = {
            {
                type = "item",
                name = get_crysalized_name(ref_item),
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_chunk_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function chunk_to_dust_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "chunk-to-dust-" .. ref_item.name,
        category = "dustifying-chunk",
        ingredients = {
            {
                type = "item",
                name = get_chunk_name(ref_item),
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_dust_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end

---@param ref_item data.ItemPrototype
local function dust_to_compound_recipe(ref_item)
    ---@type data.RecipePrototype
    local recipe = {
        type = "recipe",
        name = "dust-to-compound-" .. ref_item.name,
        category = "compounding-dust",
        ingredients = {
            {
                type = "item",
                name = get_dust_name(ref_item),
                amount = 1
            }
        },
        results = {
            {type = "item", name = get_compound_name(ref_item), amount = 1}
        },
        icon = ref_item.icon,
        icon_size = 64,
    }
    table.insert(recipes, recipe)
end


---@param ref_item data.ItemPrototype
local function add_liquid_to_compound_chain_recipes(ref_item)
    liquid_to_crystal_recipe(ref_item)
    crystal_to_chunk_recipe(ref_item)
    chunk_to_dust_recipe(ref_item)
    dust_to_compound_recipe(ref_item)
end


function add_items()
    for name, item in pairs(data.raw.item) do
        -- Check if the item is an ore
        if item.subgroup == "raw-resource" and item.name ~= "coal" then
            add_fluid(item)
            add_crystal(item)
            add_chunk(item)
            add_dust(item)
            add_compound(item)
            add_ore_recipes(item)
            add_liquid_to_compound_chain_recipes(item)
            compound_to_plate_recipe(item)
        end
    end
end


add_buildings()
add_items()

-- Prototype definitions
data:extend(buildings)
data:extend(liquids)
data:extend(crystals)
data:extend(chunks)
data:extend(dusts)
data:extend(compounds)

-- Recipe definitions
data:extend(recipe_categories)
data:extend(recipes)
