data:extend{
  {
    type = "tips-and-tricks-item-category",
    name = "RateCalculator",
    order = "l-[RateCalculator]"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-introduction",
    category = "RateCalculator",
    order = "a",
    is_title = true,
    image = "__RateCalculator__/graphics/tips-and-tricks/introduction.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-gui-overview",
    category = "RateCalculator",
    order = "b",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/gui-overview.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-gui-units",
    category = "RateCalculator",
    order = "c",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/gui-units.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-gui-entity-units",
    category = "RateCalculator",
    order = "d",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/gui-entity-units.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-gui-measures",
    category = "RateCalculator",
    order = "e",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/gui-measures.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-gui-multiplier",
    category = "RateCalculator",
    order = "f",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/gui-multiplier.png"
  },
  {
    type = "tips-and-tricks-item",
    name = "rcalc-selection-modes",
    category = "RateCalculator",
    order = "g",
    indent = 1,
    dependencies = {"rcalc-introduction"},
    trigger = {type = "dependencies-met"},
    image = "__RateCalculator__/graphics/tips-and-tricks/selection-modes.png"
  }
}
