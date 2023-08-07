import streamlit as st
import webbrowser
import re

def local_css(file_name):
    with open(file_name) as f:
        st.markdown('<style>{}</style>'.format(f.read()), unsafe_allow_html=True)

def button_as_page_link(url):
  webbrowser.open(url)

def create_sidebar():
    pages = {
      "Home": "https://ncdrugchecking.streamlit.app/",
      "NC Xylazine": "https://ncxylazine.streamlit.app/",
      "NC Overdoses": "https://ncoverdoses.streamlit.app/",
      "NC Stimulants": "https://ncstimulants.streamlit.app/",
      "NC Drug Market": "https://ncdrugmarket.streamlit.app/",
      "NC Psychedelics & Others": "https://ncpsychedelics.streamlit.app/",
      "Get Help": "https://www.streetsafe.supply/contact",
    }
    with st.sidebar:
    # map over the pages dict and return a button for each page
    # the button should have the page name as the label and the url as the param for the button_as_page_link function in the on_click param
     for page in pages:
        # create a markdown string that is an anchor tag with the url as the href value and the page name as the text
        # the anchor tag should open in a new tab
        html= "<a class='click-button' class='btn-simple' href="+pages[page]+" target='_blank'>"+page+"</a>"
        st.markdown(html, unsafe_allow_html=True)

def convert_df(df):
  return df.to_csv(index=False).encode('utf-8')

county_groups = {
     "Cherokee": 1,
     "Graham": 1,
     "Clay": 1,
     "Macon": 1,
     "Jackson": 1,
     "Swain": 1,
     "Haywood": 1,
      "Madison": 1,
      "Buncombe": 1,
      "Henderson": 1,
      "Transylvania": 1,
      "Polk": 1,
      "Rutherford": 1,
      "McDowell": 1,
      "Yancey": 1,
      "Mitchell": 1,
      "Avery": 1,
      "Burke": 1,
      "Caldwell": 1,
         "Watauga":2,
    "Ashe":2,
    "Alleghany":2,
    "Wilkes":2,
    "Yadkin":2,
    "Surry":2,
    "Stokes":2,
    "Forsyth":2,
    "Davie":2,
    "Davidson":2,
    "Rockingham":2,
    "Guilford":2,
    "Randolph":2,
    "Cleveland": 3,
    "Lincoln": 3,
    "Gaston": 3,
    "Mecklenburg": 3,
    "Catawba": 3,
    "Cabarrus": 3,
    "Union": 3,
    "Stanly": 3,
    "Anson": 3,
    "Alexander": 3,
    "Iredell": 3,
    "Rowan": 3,
    "Caswell": 4,
    "Person": 4,
    "Granville": 4,
    "Vance": 4,
    "Warren": 4,
    "Franklin": 4,
    "Wake": 4,
    "Durham": 4,
    "Orange": 4,
    "Chatham": 4,
    "Alamance": 4,
    "Wilson": 4,
    "Johnston": 4,
    "Nash": 4,
    "Montgomery": 5,
    "Moore": 5,
    "Richmond": 5,
    "Scotland": 5,
    "Hoke": 5,
    "Robeson": 5,
    "Cumberland": 5,
    "Bladen": 5,
    "Sampson": 5,
    "Pender": 5,
    "Lee": 5,
    "Harnett": 5,
    "Cumberland": 5,
    "New Hanover": 5,
    "Brunswick": 5,
    "Onslow": 6,
    "Duplin": 6,
    "Wayne": 6,
    "Greene": 6,
    "Lenoir": 6,
    "Jones": 6,
    "Pitt": 6,
    "Beaufort": 6,
    "Craven": 6,
    "Pamlico": 6,
    "Carteret": 6,
    "Hyde": 6,
    "Tyrrell": 6,
    "Washington": 6,
    "Martin": 6,
    "Bertie": 6,
    "Dare": 6,
    "Currituck": 6,
    "Camden": 6,
    "Pasquotank": 6,
    "Perquimans": 6,
    "Chowan": 6,
    "Gates": 6,
    "Halifax": 6,
    "Northampton": 6,
    "Hertford": 6,
     "Cherokee County": 1,
     "Graham County": 1,
     "Clay County": 1,
     "Macon County": 1,
     "Jackson County": 1,
     "Swain County": 1,
     "Haywood County": 1,
      "Madison County": 1,
      "Buncombe County": 1,
      "Henderson County": 1,
      "Transylvania County": 1,
      "Polk County": 1,
      "Rutherford County": 1,
      "McDowell County": 1,
      "Yancey County": 1,
      "Mitchell County": 1,
      "Avery County": 1,
      "Burke County": 1,
      "Caldwell County": 1,
         "Watauga County": 2,
    "Ashe County": 2,
    "Alleghany County": 2,
    "Wilkes County": 2,
    "Yadkin County": 2,
    "Surry County": 2,
    "Stokes County": 2,
    "Forsyth County": 2,
    "Davie County": 2,
    "Davidson County": 2,
    "Rockingham County": 2,
    "Guilford County": 2,
    "Randolph County": 2,
    "Cleveland County": 3,
    "Lincoln County": 3,
    "Gaston County": 3,
    "Catawba County": 3,
    "Mecklenburg County": 3,
    "Cabarrus County": 3,
    "Union County": 3,
    "Stanly County": 3,
    "Anson County": 3,
    "Alexander County": 3,
    "Iredell County": 3,
    "Rowan County": 3,
    "Caswell County": 4,
    "Person County": 4,
    "Granville County": 4,
    "Vance County": 4,
    "Warren County": 4,
    "Franklin County": 4,
    "Wake County": 4,
    "Durham County": 4,
    "Orange County": 4,
    "Chatham County": 4,
    "Alamance County": 4,
    "Wilson County": 4,
    "Johnston County": 4,
    "Nash County": 4,
    "Montgomery County": 5,
    "Moore County": 5,
    "Richmond County": 5,
    "Scotland County": 5,
    "Hoke County": 5,
    "Robeson County": 5,
    "Cumberland County": 5,
    "Bladen County": 5,
    "Sampson County": 5,
    "Pender County": 5,
    "Lee County": 5,
    "Harnett County": 5,
    "Cumberland County": 5,
    "New Hanover County": 5,
    "Brunswick County": 5,
    "Onslow County": 6,
    "Duplin County": 6,
    "Wayne County": 6,
    "Greene County": 6,
    "Lenoir County": 6,
    "Jones County": 6,
    "Pitt County": 6,
    "Beaufort County": 6,
    "Craven County": 6,
    "Pamlico County": 6,
    "Carteret County": 6,
    "Hyde County": 6,
    "Tyrrell County": 6,
    "Washington County": 6,
    "Martin County": 6,
    "Bertie County": 6,
    "Dare County": 6,
    "Currituck County": 6,
    "Camden County": 6,
    "Pasquotank County": 6,
    "Perquimans County": 6,
    "Chowan County": 6,
    "Gates County": 6,
    "Halifax County": 6,
    "Northampton County": 6,
    "Hertford County": 6,
}
# remove any duplicates from county_groups dict
county_groups = {k: v for k, v in county_groups.items() if v is not None}

def add_county_group(county):
  return county_groups.get(county, None)
  # map over the county_group dict and return the key if the county is in the value
  # for key, value in county_group.items():
  #   # instead of looking for exact match, use the county as a regex pattern to test each value for a match
  #   for v_ in value:
  #     pattern = re.compile(v_)
  #   # test the value against the regular expression pattern
  #     if pattern.match(county):
  #       return key