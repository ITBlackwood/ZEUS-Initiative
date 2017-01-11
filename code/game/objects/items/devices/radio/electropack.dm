/obj/item/device/electropack
	name = "electropack"
	desc = "Dance my monkeys! DANCE!!!"
	icon = 'icons/obj/radio.dmi'
	icon_state = "electropack0"
	item_state = "electropack"
	flags = CONDUCT
	slot_flags = SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	materials = list(MAT_METAL=10000, MAT_GLASS=2500)
	var/on = 1
	var/code = 2
	var/frequency = 1449
	var/shock_cooldown = 0

/obj/item/device/electropack/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] hooks [user.p_them()]self to the electropack and spams the trigger! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (FIRELOSS)

/obj/item/device/electropack/initialize()
	if(SSradio)
		SSradio.add_object(src, frequency, RADIO_CHAT)

/obj/item/device/electropack/New()
	if(SSradio)
		SSradio.add_object(src, frequency, RADIO_CHAT)
	..()

/obj/item/device/electropack/Destroy()
	if(SSradio)
		SSradio.remove_object(src, frequency)
	return ..()

/obj/item/device/electropack/attack_hand(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.back)
			user << "<span class='warning'>You need help taking this off!</span>"
			return
	..()

/obj/item/device/electropack/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/clothing/head/helmet))
		var/obj/item/assembly/shock_kit/A = new /obj/item/assembly/shock_kit( user )
		A.icon = 'icons/obj/assemblies.dmi'

		if(!user.unEquip(W))
			user << "<span class='warning'>[W] is stuck to your hand, you cannot attach it to [src]!</span>"
			return
		W.loc = A
		W.master = A
		A.part1 = W

		user.unEquip(src)
		loc = A
		master = A
		A.part2 = src

		user.put_in_hands(A)
		A.add_fingerprint(user)
		if(src.flags & NODROP)
			A.flags |= NODROP
	else
		return ..()

/obj/item/device/electropack/Topic(href, href_list)
	//..()
	var/mob/living/carbon/C = usr
	if(usr.stat || usr.restrained() || C.back == src)
		return
	if((ishuman(usr) && usr.contents.Find(src)) || usr.contents.Find(master) || (in_range(src, usr) && isturf(loc)))
		usr.set_machine(src)
		if(href_list["freq"])
			SSradio.remove_object(src, frequency)
			frequency = sanitize_frequency(frequency + text2num(href_list["freq"]))
			SSradio.add_object(src, frequency, RADIO_CHAT)
		else
			if(href_list["code"])
				code += text2num(href_list["code"])
				code = round(code)
				code = min(100, code)
				code = max(1, code)
			else
				if(href_list["power"])
					on = !( on )
					icon_state = "electropack[on]"
		if(!( master ))
			if(istype(loc, /mob))
				attack_self(loc)
			else
				for(var/mob/M in viewers(1, src))
					if(M.client)
						attack_self(M)
		else
			if(istype(master.loc, /mob))
				attack_self(master.loc)
			else
				for(var/mob/M in viewers(1, master))
					if(M.client)
						attack_self(M)
	else
		usr << browse(null, "window=radio")
		return
	return

/obj/item/device/electropack/receive_signal(datum/signal/signal)
	if(!signal || signal.encryption != code)
		return

	if(ismob(loc) && on)
		if(shock_cooldown != 0)
			return
		shock_cooldown = 1
		spawn(100)
			shock_cooldown = 0
		var/mob/M = loc
		step(M, pick(cardinal))

		M << "<span class='danger'>You feel a sharp shock!</span>"
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, M)
		s.start()

		M.Weaken(5)

	if(master)
		master.receive_signal()
	return

/obj/item/device/electropack/attack_self(mob/user)

	if(!ishuman(user))
		return
	user.set_machine(src)
	var/dat = {"<TT>Turned [on ? "On" : "Off"] -
<A href='?src=\ref[src];power=1'>Toggle</A><BR>
<B>Frequency/Code</B> for electropack:<BR>
Frequency:
<A href='byond://?src=\ref[src];freq=-10'>-</A>
<A href='byond://?src=\ref[src];freq=-2'>-</A> [format_frequency(frequency)]
<A href='byond://?src=\ref[src];freq=2'>+</A>
<A href='byond://?src=\ref[src];freq=10'>+</A><BR>

Code:
<A href='byond://?src=\ref[src];code=-5'>-</A>
<A href='byond://?src=\ref[src];code=-1'>-</A> [code]
<A href='byond://?src=\ref[src];code=1'>+</A>
<A href='byond://?src=\ref[src];code=5'>+</A><BR>
</TT>"}
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return