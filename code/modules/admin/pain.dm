/client/proc/triggtest()
	set category = "Debug.TRIGG IS AT IT AGAIN"
	set name = "AAAAAA"

	if(!check_rights(R_DEBUG))
		return
	var/datum/outfit_manager/ui = new(usr)
	ui.ui_interact(usr)

/datum/outfit_manager
	var/client/holder

	var/dummy_key
	var/static/list/allitems
	var/datum/outfit/drip = /datum/outfit/job/miner/equipped/hardsuit

/datum/outfit_manager/New(user)
	holder = CLIENT_FROM_VAR(user)
	drip = new drip

/datum/outfit_manager/ui_state(mob/user)
	return GLOB.admin_state

/datum/outfit_manager/ui_close(mob/user)
	clear_human_dummy(dummy_key)
	qdel(src)

/datum/outfit_manager/proc/init_dummy()
	dummy_key = "outfit_manager_[holder]"
	var/mob/living/carbon/human/dummy/dummy = generate_or_wait_for_human_dummy(dummy_key)
	var/mob/living/carbon/carbon_target = holder.mob
	if(istype(carbon_target))
		carbon_target.dna.transfer_identity(dummy)
		dummy.updateappearance()

	unset_busy_human_dummy(dummy_key)
	return

/datum/outfit_manager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BigPain", "Outfit-O-Tron 9000")
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/outfit_manager/proc/entry(data)
	if(ispath(data, /obj/item))
		var/obj/item/item = data
		return list(
			"path" = item,
			"name" = initial(item.name),
			"sprite" = icon2base64(icon(initial(item.icon), initial(item.icon_state))) //at this point initializing the item is probably faster tbh
			)

	return data

/datum/outfit_manager/proc/serialize_outfit()
	var/list/outfit_slots = drip.get_json_data()
	. = list()
	for(var/key in outfit_slots)
		var/val = outfit_slots[key]
		. += list("[key]" = entry(val))

/datum/outfit_manager/ui_data(mob/user)
	var/list/data = list()

	data["outfit"] = serialize_outfit()

	var/datum/preferences/prefs = holder.prefs
	var/datum/outfit/temp_drip = drip //some pre_equip actions reset certain slots i.e /datum/outfit/job/pre_equip()
	var/icon/dummysprite = get_flat_human_icon(null, prefs = prefs, dummy_key = dummy_key, showDirs = list(SOUTH), outfit_override = temp_drip)
	data["dummy64"] = icon2base64(dummysprite)

	return data

/datum/outfit_manager/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	. = TRUE
	switch(action)
		if("click")
			choose_item(params["slot"])
		if("save")
			GLOB.custom_outfits |= (drip)

/datum/outfit_manager/proc/edit_item(slot, obj/item/choice)
	if(ispath(choice))
		drip.vars[slot] = choice

//this proc will try to give a good selection of items that the user can choose from
//it does *not* give a selection of all items that can fit in a slot because lag;
//most notably the hand and pocket slots because they accept pretty much anything
//also stuff that fits in the belt and back slots are scattered pretty much all over the place
/datum/outfit_manager/proc/choose_item(slot)
	var/list/options = list()
	if(!allitems)
		allitems = typesof(/obj/item)

	switch(slot)
		if("head")
			options = typesof(/obj/item/clothing/head)
		if("glasses")
			options = typesof(/obj/item/clothing/glasses)
		if("ears")
			options = typesof(/obj/item/radio/headset)

		if("neck")
			options = typesof(/obj/item/clothing/neck)
		if("mask")
			options = typesof(/obj/item/clothing/mask)

		if("uniform")
			options = typesof(/obj/item/clothing/under)
		if("suit")
			options = typesof(/obj/item/clothing/suit)
		if("gloves")
			options = typesof(/obj/item/clothing/gloves)

		if("suit_store")
			var/obj/item/clothing/suit/suit = drip.suit
			if(suit)
				suit = new suit //initial() doesn't like lists
				options = suit.allowed
		if("belt")
			options = typesof(/obj/item/storage/belt)
		if("id")
			options = typesof(/obj/item/card/id)

		if("l_hand")
			choose_any_item(slot)
		if("back")
			options = typesof(/obj/item/storage/backpack)
		if("r_hand")
			choose_any_item(slot)

		if("l_pocket")
			choose_any_item(slot)
		if("shoes")
			options = typesof(/obj/item/clothing/shoes)
		if("r_pocket")
			choose_any_item(slot)

	if(length(options))
		edit_item(slot, tgui_input_list(holder, "Choose an item", "Outfit-O-Tron 9000", options))



/datum/outfit_manager/proc/choose_any_item(slot)
	if(!allitems)
		allitems = typesof(/obj/item)

	edit_item(slot, tgui_input_list(holder, "Choose an item", "Outfit-O-Tron 9000", allitems))
