package ardan.rego

import future.keywords.if
import future.keywords.in

default ruleAny := false

default ruleAdminOnly := false

default ruleUserOnly := false

default ruleAdminOrSubject := false

roleUser := "USER"

roleAdmin := "ADMIN"

roleAll := {roleAdmin, roleUser}

ruleAny if {
	claim_roles := {role | some role in input.Roles}
	input_roles := roleAll & claim_roles
	count(input_roles) > 0
}

ruleAdminOnly if {
	claim_roles := {role | some role in input.Roles}
	input_admin := {roleAdmin} & claim_roles
	count(input_admin) > 0
}

ruleUserOnly if {
	claim_roles := {role | some role in input.Roles}
	input_user := {roleUser} & claim_roles
	count(input_user) > 0
}

ruleAdminOrSubject if {
	claim_roles := {role | some role in input.Roles}
	input_admin := {roleAdmin} & claim_roles
	count(input_admin) > 0
} else if {
	claim_roles := {role | some role in input.Roles}
	input_user := {roleUser} & claim_roles
	count(input_user) > 0
	input.UserID == input.Subject
}
