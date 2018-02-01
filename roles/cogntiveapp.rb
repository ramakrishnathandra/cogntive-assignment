name "cogntiveapp"
description "cogntiveapp Chef role"
run_list "recipe[cogntiveapp]"
override_attributes({
  "starter_name" => "Ramakrishna Thandra",
})

