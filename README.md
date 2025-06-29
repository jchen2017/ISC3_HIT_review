# ISC3_HIT_review
STATA code to support analysis and synthesis of data for the ISC3 HIT scoping review.

Owens C, Chen J, Xu R, Angier H, Huebschmann GA, Fukunaga MI, Chaiyachati KH, Rendle K, Robien K, DiMartino L, Amante DJ, Faro J, Kepper M, Ramsey A, Bressman E, Gold R. on behalf of National Cancer Institute’s Consortium for Cancer Implementation Science (CCIS). Implementation of Health Information Technology (HIT) Approaches for Secondary Cancer Prevention in Primary Care: A Scoping Review. JMIR Cancer. 2024 Apr 30;10:e49002. doi: 10.2196/49002. PMID: 38687595; PMCID: PMC11094604

***************************************

copyright 2022 Jinying Chen, iDAPT Cancer Control Center & UMass Chan Medical School

Licensed under the MIT License (the "License");
you may not use this file except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
***************************************

To run the code, please put the accompanied ado file table1v3.ado in your personal ado directory like C:\ado\personal
 
1. Setting input data directory

 replace [[input dir]] in the definition of the global macro datadir in the file analyze_HIT_scoping_review_data.do
 (around line 43) by the directory that holds the input files (in xlsx format)

2. Updating input data files

  replace the file and worksheet names for lines starting with "import excel" in each program 

3. Program running order

(1) table_1_2

(2) gen_data_for_table3

(3) gen_data_for_table6

(4) other programs

