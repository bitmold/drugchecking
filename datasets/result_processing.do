

// Import results files

do "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/getfile.do"

clear all
frames reset

// Import City Locations for Programs
import excel "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/LabResults.xlsx", sheet("ProgramInfo") firstrow clear
drop text
rename county p_city
rename state p_state
save programloc, replace


// Import Lab Data
import excel "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/LabResults.xlsx", sheet("LAB data") firstrow clear

* Keep only samples with completed lab analysis and relevant variables
keep if lab_status=="complete"
keep sampleid substance abundance method date_complete
duplicates drop
save lab, replace


// Import Card Data
import excel "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/LabResults.xlsx", sheet("CARD data") firstrow case(lower) clear
drop linkedsample howlongagowasthesampleobta lab_note* 

* Keep only US samples
drop if state=="international"

* Replace missing location data on card with mailing location of program
merge m:1 program using programloc, keep(1 3) nogen
replace location=p_city if location=="" | location=="not specified"
replace state=p_state if state=="" | location=="not specified"
drop p_city p_state
erase programloc.dta

save card, replace

// Merge lab and card data, keeping only complete US samples
merge 1:m sampleid using lab, keep(3) nogen
save full_analysis, replace

* Create list of analysis-ready sample IDs
keep sampleid
duplicates drop
save keeplist, replace

* Create and restrict lab/card frames to samples meeting eligibility criteria, add variable labels and notes
use card, clear
merge 1:1 sampleid using keeplist, keep(3) nogen
distinct sampleid


la var sampletype "Verbatim sample type on card"
la var expectedsubstance "Verbatim expected substance on card"
la var program "Program name"
la var date "Date of sample collection"
la var color "Color circled on card"
la var texture "Texture circled on card"
la var sensations "Sensations circled on card"
note sensations: "Added in card version 3"
note  texture: "Added in card version 3"
note  texture_notes: "Added in card version 3"
note  sensation_notes: "Added in card version 3"
la var texture_notes "Texture verbatim write-in"
la var sensation_notes "Sensations verbatim write-in"
la var state "State sample collected"
note state: "Minimum required geographic identifier."
la var location "City or County"
note location: "Write-in on card, minimally standardized. Could be neighborhood, city, or county. Not required. Filled in with program mailing address city if unspecified."
la var overdose "Invovlement in overdose"
note overdose: "Added in card version 3"
la var overdose_notes "Verbatim description of overdose event. Not routinely completed."
la var card_notes "Any additional messages on card or observations"

frame put sampleid sampletype expectedsubstance program date color texture sensations texture_notes sensation_notes state location overdose overdose_notes, into(card)

use lab, clear
merge m:1 sampleid using keeplist, keep(3) nogen
distinct sampleid
erase keeplist.dta

la var sampleid "Sample ID"
la var substance "Confirmed substance detected in lab. Standardized chemical name."
la var abundance "Primary or trace level of abundance as detected by GCMS. Trace is specified, and primary substances have missing value."
la var method "Lab method used to confirm presence of substance."
la var date_complete "Date analysis completed by UNC lab."

frame put sampleid substance abundance method date_complete, into(lab)

* Link frames
frame change lab
frlink m:1 sampleid, frame(card)
 

*use full_analysis, clear

// Create subsets for different customers
** To be completed later

// Describe lab sample 
frame lab: distinct sampleid
frame card: distinct sampleid



// Process Card data
frame change card

* Sample type consolidation
gen collection=sampletype
la var collection "Collection method, consolidated for reporting"
order collection, a(sampletype)
replace collection="multiple methods" if regexm(sampletype,";")

* Expected substance

** Create drug classes
gen expect_opioid=0
replace expect_opioid=1 if regexm(lower(expectedsubstance),"heroin|fentanyl|percocet|m30|roxicodone")
la var expect_opioid "1 if expected heroin or fentanyl circled on card, or specific opioid named"
note expect_opioid: "Named opioid could include Percocet, Vicodin, Roxicodone, etc."

gen expect_fentanyl=0
replace expect_fentanyl=1 if regexm(lower(expectedsubstance),"fentanyl")
la var expect_fentanyl "1 if expected fentanyl circled on card"

gen expect_xylazine=0
replace expect_xylazine=1 if regexm(lower(expectedsubstance),"xylazine") | regexm(lower(sensation_notes),"xylazine")
la var expect_xylazine "1 if expected xylazine circled on card or mentioned in sensation notes"
note expect_xylazine: "Added in version 3 of card"

gen expect_stimulant=0
replace expect_stimulant=1 if regexm(lower(expectedsubstance),"cocaine|crack|meth")
la var expect_stimulant "1 if expected cocaine, crack, methamphetamine circled on card"

gen expect_benzo=0
replace expect_benzo=1 if regexm(lower(expectedsubstance),"benzo|xanax|alprazolam") | regexm(lower(sensation_notes),"benzo")
la var expect_benzo "1 if expected benzodiazepine circled on card or specific substance named"

gen expect_cannabis=0
replace expect_cannabis=1 if regexm(lower(expectedsubstance),"weed|cbd|delta|canna|pot") | regexm(texture,"plant") | regexm(texture_notes,"joint|weed|pot")
la var expect_cannabis "1 if expected CBD, Delta-8 or weed circled on card"

gen expect_hall=0
replace expect_hall=1 if regexm(lower(expectedsubstance),"lsd|mda|molly|mdma|mda|mushroom|dmt|ketamine|esketamine|ecstacy|psilocybin|eutylone")
la var expect_hall "1 if expected hallucinogen"
note expect_hall: "lsd|mda|molly|mdma|mushroom|dmt|ketamine|ecstacy|psilocybin"

order expect_*, a(expectedsubstance)

** Date of sample collection
gen date_collect = date(date, "MDY")
order date_collect, a(sampleid)
format date_collect %td
la var date_collect "Date sample collected"
drop date

** Color
replace color=lower(color)
replace color="" if color=="not specified"
replace color="" if color=="not specified"

*** Manual correction for complex color descriptions that did not meet validation rules of data entry sheet
replace color="pink; lavendar; pale orange; light blue; aqua/teal" if sampleid=="300349"

gen bright_color=0
replace bright_color=1 if color!="white" & !regexm(color,"off-white") & !regexm(color,"tan") & !regexm(color,"brown") & !regexm(color,"clear") & color!="opaque" & color!="" & !regexm(color,"gray|grey") & !regexm(color,"black") & color!="soft" & color!="cloudy; white" & color!="white; cloudy" & !regexm(color,"beige")
order bright_color, a(color)
la var bright_color "Bright color of original sample reported"
note bright_color: "Recoded variable that excludes white, gray, tan, beige, black, brown, and similar variations."

** Program
order program location state , a(sampleid)

** Overdose involvement
gen od=.
replace od=0 if regexm(overdose,"not overdose related")
replace od=1 if overdose=="involved in OD" | regexm(lower(sensation_notes),"narcan|naloxone") | regexm(lower(overdose_notes),"narcan|naloxone|overdose|fell out|pass out|passed out") | regexm(overdose_notes,"OD")
order od, a(overdose)
la var od "Recoded overdose involvement for reporting"
note od: "1 if OD related, 0 if explicitly stated sample was not involved in an overdose. Set to missing if OD involvement was not reported. Could be fatal or non-fatal overdose. Question was added to card in Version 2."
tab od, m

label define odlabel 0 "not involved" 1 "Overdose reported"
label values od odlabel

gen fatal_od=.
replace fatal_od=1 if regexm(lower(overdose_notes),"dead|death|fatal")
replace fatal_od=. if regexm(lower(overdose_notes),"non-fatal|nonfatal")
la var fatal_od "Derived flag (1) if fatal overdose was mentioned in overdose_notes."
note fatal_od: "Not considered a complete case enumeration because not uniformly reported."

** Sensations
replace sensations=lower(sensations)
replace sensations="" if sensations=="not specified" | sensations=="unknown"

gen sen_strength=.
replace sen_strength=0 if regexm(sensations,"normal|typical")
replace sen_strength=-1 if regexm(sensations,"weaker")
replace sen_strength=1 if regexm(sensations, "stronger") | regexm(lower(sensation_notes),"strong") | regexm(lower(overdose_notes),"strong")
label define sennormal -1 "weaker" 0 "normal" 1 "stronger"
label values sen_strength sennormal
la var sen_strength "Derived 3-level flag where -1 weaker, 0 normal, 1 stronger"

gen sen_weird=.
replace sen_weird=1 if regexm(sensations,"weird|unpleasant") | regexm(lower(sensation_notes),"strange|not normal|bad feeling|weird|sick|dizzy|vertigo|nystagmus|hurt|odd|bad reaction") | regexm(lower(overdose_notes),"wierd")  
la var sen_weird "Derived flag (1) if sensation was noted as 'weird' or 'unpleasant' or notes indicating bad feelings."
note sen_weird: "Check sensations and sensation_notes to verify. See code for search strings."

gen sen_hall=.
replace sen_hall=1 if regexm(sensations,"hallucin") | regexm(lower(sensation_notes),"hallucin")
la var sen_hall "Derived flag (1) if sensation included hallucinations. Check sensations and sensation_notes to verify."
note sen_hall: "Check sensations and sensation_notes to verify. See code for search strings."

gen sen_up=.
replace sen_up=1 if regexm(sensations,"more up|jittery") | regexm(lower(sensation_notes),"more up")
la var sen_up "Derived flag (1) if sensation was described as 'more up'."
note sen_up: "Check sensations and sensation_notes to verify. See code for search strings."

gen sen_down=.
replace sen_down=1 if regexm(sensations,"more down") | regexm(lower(sensation_notes),"sedat|tranq|downer|sleep|drowsy|fell out|fall out|nod|went out|black out|tired|knock|slow|slept|pass|downer") | regexm(lower(overdose_notes),"unconcious|unconscious|sedat|fall out")
la var sen_down "Derived flag (1) if sensation was described as 'more down' or notes indicating down sensations."
note sen_down: "Check sensations and sensation_notes and overdose_notes to verify. See code for search strings."

gen sen_nice=.
replace sen_nice=1 if regexm(sensations,"nice") | regexm(lower(sensation_notes),"good stuff|awesome|good quality|nice visuals")
la var sen_nice "Derived flag (1) if sensation was circled as 'nice'."
note sen_nice: "Check sensations and sensation_notes to verify. See code for search strings."

gen sen_long=.
replace sen_long=1 if regexm(sensations,"long") | regexm(lower(sensation_notes),"long")
la var sen_long "Derived flag (1) if sensation was described as 'long'. Check sensations and sensation_notes to verify."

gen sen_burn=.
replace sen_burn=1 if regexm(sensations,"burn") | regexm(lower(sensation_notes),"burn")
replace sen_burn=. if regexm(lower(sensation_notes),"heart burn")
la var sen_burn "Derived flag (1) if burning sensation was described. Check sensations and sensation_notes to verify."
note sen_burn: "Contains negation rule for 'heart burn'"

gen sen_skin=.
replace sen_skin=1 if regexm(lower(sensation_notes),"absces|wound|skin|arms|leg|mouth") | regexm(lower(overdose_notes),"wounds|cyst")
la var sen_skin "Derived flag (1) if skin involvement noted in free text, like abscesses."
note sen_skin: "Check sensations and sensation_notes, overdose_notes to verify. See code for search strings."

gen sen_seizure=.
replace sen_seizure=1 if regexm(lower(overdose_notes),"seizure") | regexm(lower(overdose_notes),"seizure") | regexm(sensations, "seizure")
la var sen_seizure "Derived flag if seizures were noted on sensations, or overdose/sensation notes."
note sen_seizure: "Check text match on overdose_notes and sensation_notes for drug 'seizure'."

order sen_*, a(sensations)


** Texture
replace texture="" if texture=="not specified" | texture=="unknown"

gen pill=.
replace pill=1 if regexm(texture,"pill") | regexm(lower(texture_notes),"presser|pressed|30|fake|rx|pill|xanax")
la var pill "Composite flag (1) if indication that sample was from a pill"

gen tar=.
replace tar=1 if regexm(texture_notes,"tar")
replace tar=1 if regexm(texture,"oil") & expect_opioid==1
la var tar "Derived flag (1) if notes on card or conversations with donor indicate sample was black tar heroin. Also marked tar if texture is oil/wax and the expected subsance is an opioid."

gen powder=.
replace powder=1 if regexm(texture,"powder")

gen plant=.
replace plant=1 if regexm(texture,"leaf|plant")
la var plant "Sample from plant or leaf noted on card."

gen crystals=.
replace crystals=1 if regexm(texture, "crystal")
la var crystals "Texture noted as crystals."

gen lustre=.
replace lustre=-1 if regexm(texture, "dull")
replace lustre=1 if regexm(texture, "shiny")
la var lustre "Lustre either shiny (1) or dull (-1). Cannot be both."
label define lustre_label -1 "dull" 1 "shiny"
label values lustre lustre_label

order tar pill powder plant crystals lustre, a(texture)

* Create indicator for if this sample was submitted to UNC as part of "confirmatory" testing for FTIR 
gen confirmatory=0
la var confirmatory "Submitted from FTIR site for confirmatory testing"
note confirmatory: "Confirtmatory or complementary testing with GCMS"

save card_processed, replace

// Process Lab data

frame change lab

gen primary=0
replace primary=1 if abundance==""
la var primary "Primary drug(s) confirmed in lab"

gen trace=0
replace trace=1 if abundance!=""
la var trace "Trace substance detected in lab"
note trace: "Includes trace and 'indication of' designations"

gen lab_null=.
replace lab_null=1 if substance=="no compounds of interest detected"
la var lab_null "Derived flag (1) if no compounds of interest detected."
note lab_null: "For non-derivitized GCMS, this means no small psychoactive or biological molecules detected."

bysort sampleid: gen temp=_n
bysort sampleid: egen lab_num_substances_any=count(temp)
drop temp
la var lab_num_substances_any "Total number of substances detected"
note lab_num_substances_any: "Includes substances in primary and trace abundance."

bysort sampleid: gen temp=_n if abundance==""
bysort sampleid: egen lab_num_substances=count(temp)
drop temp
la var lab_num_substances "Total number of PRIMARY substances detected"
note lab_num_substances: "Priamry substances only. Does NOT include substances in trace abundance."

* For specific substances, the convention is lab_ to indicate lab result, _any to indicate presence in trace or abundance
* Conversely, if lab_substance, the substance was detected as a primary constituent.
* In general, toxic substances (like levamisole or xylazine) are created with an "_any" match,
* meaning they should be present in either primary or trace abundance. 
* On the other hand, psychoactive substances (like gabapentin) are matched in the derived
* variables below if they are a primary constituent of the sample. 
* Fentanyl and methamphetamine are execeptions, where both primary-only and primary+trace are created
* as separate variables with the latter being designated with _any.

gen lab_fentanyl=0
replace lab_fentanyl=1 if substance=="fentanyl" & abundance==""
la var lab_fentanyl "fentanyl detected in lab"
note lab_fentanyl: "Exact match for fentanyl as a primary substance, does not include analogues."

gen lab_fentanyl_any=0
replace lab_fentanyl_any=1 if substance=="fentanyl"
la var lab_fentanyl_any "fentanyl detected in any abundance"
note lab_fentanyl_any: "Exact match for fentanyl as a primary or trace substance, does not include analogues."

gen lab_xylazine=0
replace lab_xylazine=1 if substance=="xylazine" & abundance==""
la var lab_xylazine "xylazine detected in lab"
note lab_xylazine: "Exact match for xylazine as a primary substance, does not include other alpha-2 agonists."

gen lab_xylazine_any=0
replace lab_xylazine_any=1 if substance=="xylazine"
la var lab_xylazine_any "xylazine detected in any abundance"
note lab_xylazine_any: "Exact match for xylazine as a primary or trace substance, does not include other alpha-2 agonists."

gen lab_meth=0
replace lab_meth=1 if substance=="methamphetamine" & abundance==""
la var lab_meth "xylazine detected in lab"
note lab_meth: "Exact match for methamphetamine as a primary substance."

gen lab_meth_any=0
replace  lab_meth_any=1 if substance=="methamphetamine"
la var  lab_meth_any "methamphetamine detected in lab in any abundance"
note lab_meth_any: "Exact match for methamphetamine in primary or trace abundance."

gen lab_caffeine=0
replace lab_caffeine=1 if substance=="caffeine" & abundance==""
la var lab_caffeine "caffeine detected in lab"
note lab_caffeine: "Exact match for caffeine as a primary substance."

gen lab_gabapentin=0
replace lab_gabapentin=1 if substance=="gabapentin" & abundance==""
la var lab_gabapentin "gabapentin detected in lab"
note lab_gabapentin: "Exact match for gabapentin as a primary substance."

gen lab_levamisole_any=0
replace lab_levamisole_any=1 if substance=="levamisole"
la var lab_levamisole_any "levamisole detected in lab"
note lab_levamisole_any: "Exact match for levamisole in primary or trace abundance."

gen lab_mdma=0
replace lab_mdma=1 if substance=="3,4-MDMA"
la var lab_mdma "3,4-MDMA detected in lab"
note lab_mdma: "Exact match for 3,4-MDMA as a primary substance."

gen lab_tramadol=0
replace lab_tramadol=1 if substance=="tramadol"
la var lab_tramadol "tramadol detected in lab"
note lab_tramadol: "Exact match for tramadol as a primary substance."

gen lab_carfentanil=0
replace lab_carfentanil=1 if substance=="carfentanil" & abundance==""
la var lab_carfentanil "carfentanil detected in lab"
note lab_carfentanil: "Exact match for tramadol as a primary substance."

gen lab_carfentanil_any=0
replace lab_carfentanil_any=1 if substance=="carfentanil"
la var lab_carfentanil_any "carfentanil detected in lab"
note lab_carfentanil_any: "Exact match for tramadol in primary or trace abundance."


// Impurities and drug categories
* These commands pull in the chem dictionary from GitHub and use the categoriezed columns to 
* create derived variables that classify the substance.
/*
** cocaine impurities
frame create cocaine
frame change cocaine
import delimited "https://raw.githubusercontent.com/opioiddatalab/drugchecking/main/chemdictionary/chemdictionary.csv"
keep if cocaine_impurities==1
keep substance cocaine_impurities
gen i=_n
reshape wide substance, i(cocaine_impurities) j(i) 
keep substance* 
foreach var of varlist subs* {
	replace `var'=`"""'+`var'+`"""'+","
}
egen search=concat(subs*)
replace search = substr(search, 1, length(search) - 1) if substr(search, -1, 1) ==  ","
keep search
local find=search[1]
frame change lab
gen lab_cocaine_impurity=0
replace lab_cocaine_impurity=1 if inlist(substance,`find')
la var lab_cocaine_impurity "cocaine impurities detected"
note lab_cocaine_impurity: "Known cocaine processing impurities, metabolites, and starting material detected in primary or trace abundance."
note lab_cocaine_impurity: `find'
frame drop cocaine


** heroin impurities
frame create heroin
frame change heroin
import delimited "https://raw.githubusercontent.com/opioiddatalab/drugchecking/main/chemdictionary/chemdictionary.csv"
keep if heroin_impurities==1
keep substance heroin_impurities
gen i=_n
reshape wide substance, i(heroin_impurities) j(i) 
keep substance* 
foreach var of varlist subs* {
	replace `var'=`"""'+`var'+`"""'+","
}
egen search=concat(subs*)
replace search = substr(search, 1, length(search) - 1) if substr(search, -1, 1) ==  ","
keep search
local find=search[1]
frame change lab
gen lab_heroin_impurity=0
replace lab_heroin_impurity=1 if inlist(substance,`find')
la var lab_heroin_impurity "heroin impurities detected"
note lab_heroin_impurity: "Known heroin processing impurities, metabolites, and starting material detected in primary or trace abundance."
note lab_heroin_impurity: `find'
frame drop heroin

*/
** Substituted cathinones

cd "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/"
do categorize "designer_benzos"
do categorize "benzos"
do categorize "nitazenes"
do categorize "opiates_opioids"
do categorize "synthetic_cannabinoids"
do categorize "meth_impurities"
do categorize "mdma_impurities"
do categorize "cocaine_impurities"
do categorize "common_cuts"
do categorize "heroin_impurities"
do categorize "cannabinoids"
do categorize "fentanyl_impurities"
do categorize "p_fluorofentanyl_impurities"
do categorize "substituted_cathinones"


/*
foreach i of local drug {
frame create temp
frame change temp
import delimited "https://raw.githubusercontent.com/opioiddatalab/drugchecking/main/chemdictionary/chemdictionary.csv"
keep if `i'==1
keep substance `i'
gen i=_n
reshape wide substance, i(`i') j(i) 
keep substance* 
foreach var of varlist subs* {
	*replace `var'=`"""'+`var'+`"""'+","
	replace `var'=`var'+"|"
}
egen search=concat(subs*)
replace search = substr(search, 1, length(search) - 1) if substr(search, -1, 1) ==  "|"
replace search = `"""'+search+`"""'
keep search
local find=search[1]
frame change lab
gen lab_`i'=regexm(substance,`find')
la var lab_`i' "Detected as primary or trace"
note lab_`i': "`find'"
frame drop temp
}


** CREATE MORE CATEGORIES
** cannabinoids, hallucinogens, opioids, benzos, stimulants, fentanyl analogues
*/

* Save dataset for internal analysis
*drop card
save "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/lab_detail.dta", replace

// Merge in lab results to card data to create analytic dataset

frame copy lab merge
frame change merge

collapse (max) date_complete primary trace lab_*, by(sampleid)

* Clean up logic for samples with no substances detected
replace lab_num_substances_any=0 if lab_null==1
replace lab_num_substances=0 if lab_null==1
replace primary=0 if lab_null==1

* Update notes and labels for codebook becasue they don't transfer with collapse/merge
la var sampleid "Sample ID assigned by UNC from vial or card"
la var date_complete "Date lab analysis completed"
la var primary "Primary drug(s) confirmed in lab"
la var trace "Trace substance detected in lab"
note trace: "Includes trace and 'indication of' designations"
la var lab_null "Derived flag (1) if no compounds of interest detected."
note lab_null: "For non-derivitized GCMS, this means no small psychoactive or biological molecules detected."
la var lab_num_substances_any "Total number of substances detected"
note lab_num_substances_any: "Includes substances in primary and trace abundance."
la var lab_num_substances "Total number of PRIMARY substances detected"
note lab_num_substances: "Priamry substances only. Does NOT include substances in trace abundance."
la var lab_fentanyl "fentanyl detected in lab"
note lab_fentanyl: "Exact match for fentanyl as a primary substance, does not include analogues."
la var lab_fentanyl_any "fentanyl detected in any abundance"
note lab_fentanyl_any: "Exact match for fentanyl as a primary or trace substance, does not include analogues."
la var lab_xylazine "xylazine detected in lab"
note lab_xylazine: "Exact match for xylazine as a primary substance, does not include other alpha-2 agonists."
la var lab_xylazine_any "xylazine detected in any abundance"
note lab_xylazine_any: "Exact match for xylazine as a primary or trace substance, does not include other alpha-2 agonists."
la var lab_meth "xylazine detected in lab"
note lab_meth: "Exact match for methamphetamine as a primary substance."
la var  lab_meth_any "methamphetamine detected in lab in any abundance"
note lab_meth_any: "Exact match for methamphetamine in primary or trace abundance."
la var lab_caffeine "caffeine detected in lab"
note lab_caffeine: "Exact match for caffeine as a primary substance."
la var lab_gabapentin "gabapentin detected in lab"
note lab_gabapentin: "Exact match for gabapentin as a primary substance."
la var lab_levamisole_any "levamisole detected in lab"
note lab_levamisole_any: "Exact match for levamisole in primary or trace abundance."
la var lab_mdma "3,4-MDMA detected in lab"
note lab_mdma: "Exact match for 3,4-MDMA as a primary substance."
la var lab_tramadol "tramadol detected in lab"
note lab_tramadol: "Exact match for tramadol as a primary substance."
la var lab_carfentanil "carfentanil detected in lab"
note lab_carfentanil: "Exact match for tramadol as a primary substance."
la var lab_carfentanil_any "carfentanil detected in lab"
note lab_carfentanil_any: "Exact match for tramadol in primary or trace abundance."
la var lab_cocaine_impurities_any "cocaine impurities detected"
note lab_cocaine_impurities_any: "Known cocaine processing impurities, metabolites, and starting material detected in primary or trace abundance."
la var lab_heroin_impurities_any "heroin impurities detected"
note lab_heroin_impurities_any: "Known heroin processing impurities, metabolites, and starting material detected in primary or trace abundance."
note lab_common_cuts_any: "If only GCMS was used, this may not detect all large molecule (e.g., sugars) cuts. Derivitized GCMS and FTIR are more able to identify these molecules. Therefore this field should be more accurately interpreted as common small molecule  cuts that are likely to be psychoactive or have key physiological roles."

save merge, replace

frame change card

merge 1:1 sampleid using merge, nogen


** Save dataset for internal analysis
save "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/analysis_dataset.dta", replace


// Save public demo datasets with name and location redacted

do "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/savepublic.do"


note: "Example dataset (N=20) from UNC lab drug checking services. Lab results, notes, sensations, etc. are real, but locations have been redacted."

save "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/analysis_dataset.dta", replace

*** SAS
export sasxport8 "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/analysis_dataset.v8xpt", replace

*** Excel
export excel using "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/analysis_dataset.xlsx", firstrow(variables) nolabel replace

*** Delimited CSV (tab)
export delimited using "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/analysis_dataset.csv", delimiter(tab) replace


// Generate codebook on public data

log using "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/unc_druchecking_codebook.txt", text replace
codebook, n h
log close
			

// Save public lab detail file

frame change lab
do "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/savepubliclab.do"


save "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/lab_detail.dta", replace

** SAS
export sasxport8 "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/lab_detail.v8xpt", replace

** Excel
export excel using "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/lab_detail.xlsx", firstrow(variables) nolabel replace

** Delimited CSV (tab)
export delimited using "/Users/nabarun/Dropbox/Mac/Documents/GitHub/drugchecking/datasets/lab_detail.csv", delimiter(tab) replace

	
// Save custom datasets for each client in a separate GitHub repository

** Western North Carolina (STEADY + Holler)
do "/Users/nabarun/Dropbox/Mac/Documents/GitHub/dc_internal/export_wnc.do"




