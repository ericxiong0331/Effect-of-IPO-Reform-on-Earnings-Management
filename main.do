cd "C:\Users\32976\Desktop\大四下\毕业论文\数据\2024.5.14程序\ROA" 
use Startdata.dta, clear

set scheme s1mono 
global xlist  "size lev mfee top1 zindex sindex premium vcpe age"

winsor2 droa droe size lev mfee top1 zindex sindex premium, cuts(1 99) replace
gen roa = droa
gen roe = droe

******************************************描述性统计**************************************

outreg2 using summary.xlsx, replace sum(detail) keep(droa droe registration_m size lev mfee top1 zindex sindex premium vcpe age) eqkeep(mean sd p1 p25 p50 p75 p99)
******************************************1.平行趋势图**************************************
/*use Startdata.dta
egen mean_y=mean(droa), by(year treat)
graph twoway (connect mean_y year if treat==1,sort) (connect mean_y year if treat==0,sort lpattern(dash)), ///
xline(2019,lpattern(dash) lcolor(gray)) ///
ytitle("y") xtitle("年度") ///
ylabel(,labsize(*0.75)) xlabel(,labsize(*0.75)) ///
legend(label(1 "处理组") label( 2 "控制组")) ///图例
xlabel(2017 (1) 2022)  graphregion(color(white)) //白
*/

******************************************************一、基准回归 *********************************
reg roa registration_m i.year i.ind_zz, robust
outreg2 using 基础回归.docx,replace  bdec(4) tdec(4) rdec(4) ctitle(droa) keep(registration_m) addtext(ind fe, yes,year fe, yes)

reg roa registration_m  $xlist  i.year i.ind_zz, robust
outreg2 using 基础回归.docx,append bdec(4) tdec(4) rdec(4) ctitle(droa) keep(registration_m $xlist ) addtext(ind fe, yes,year fe, yes)

reg roe registration_m i.year i.ind_zz, robust
outreg2 using 基础回归.docx,append  bdec(4) tdec(4) rdec(4) ctitle(droe) keep(registration_m) addtext(ind fe, yes,year fe, yes)

reg roe registration_m  $xlist  i.year i.ind_zz, robust
outreg2 using 基础回归.docx,append bdec(4) tdec(4) rdec(4) ctitle(droe) keep(registration_m $xlist ) addtext(ind fe, yes,year fe, yes)


*****************************************************二、平行趋势检验******************************

gen afterevent = year - policy if treat==1 // policy为政策开始的年份， afterevent为当年和政策发生年之差，0代表发生当年，以此类推
tab afterevent, gen(event)  // 对于每一个afterevent的取值都生产一个哑变量，event1就是afterevent=-3时取1，其他取0，以此类推
forvalues i = 1/7{
	replace event`i' = 0 if event`i' == . // 将缺失值均替换为0，代表是对照组
}
drop event3 // 以event3作为基期
reg roa event*  $xlist i.ind i.year, r //event*代表所有event变量
outreg2 using 平行趋势检验.docx,replace tstat bdec(4) tdec(4) rdec(4) ctitle(roa) keep(event1 event2 event4 event5 event6 event7) addtext(ind fe, yes,year fe, yes)

coefplot, ///
   keep(event1 event2 event4 event5 event6 event7)  ///
   coeflabels(event1 = "-3"  ///
   event2 = "-2"             ///
   event4 = "0"              ///
   event5 = "1"              ///
   event6  = "2"             ///
   event7  = "3"             ///
  )   ///
   vertical                  ///
   yline(0,lp(dash))         ///
   xline(3,lp(dash))	     ///
   ytitle("回归系数")        ///
   xtitle("政策时点")		 ///
   addplot(line @b @at)      ///
   ciopts(recast(rcap))      ///
   title("ΔROA")			 ///
   scheme(s1mono)
graph export "parallel_test_roa.png",as(png) replace width(800) height(600)

reg roe event*  $xlist i.ind i.year, r //event*代表所有event变量
outreg2 using 平行趋势检验.docx,replace tstat bdec(4) tdec(4) rdec(4) ctitle(roa) keep(event1 event2 event4 event5 event6 event7) addtext(ind fe, yes,year fe, yes)

coefplot, ///
   keep(event1 event2 event4 event5 event6 event7)  ///
   coeflabels(event1 = "-3"   ///
   event2 = "-2"             ///
   event4 = "0"              ///
   event5 = "1"              ///
   event6  = "2"             ///
   event7  = "3"             ///
  )   ///
   vertical                  ///
   yline(0,lp(dash))         ///
   xline(3,lp(dash))	     ///
   ytitle("回归系数")        ///
   xtitle("政策时点")		 ///
   addplot(line @b @at)      ///
   ciopts(recast(rcap))      ///
   title("ΔROE")			 ///
   scheme(s1mono)
graph export "parallel_test_roe.png",as(png) replace width(800) height(600)

************************多时点did安慰剂检验*******

use Startdata.dta, clear

global xlist  "size lev mfee top1 zindex sindex premium vcpe age"

winsor2 droa droe size lev mfee top1 zindex sindex premium, cuts(1 99) replace
gen roa= droa
gen roe= droe

cap erase "simulations_roa.dta"
permute registration_m beta = _b[registration_m], ///
 reps(500) rseed(123) saving("simulations_roa.dta"): ///
  reg roa registration_m $xlist i.ind_zz i.year, r
  
use "simulations_roa.dta", clear
#delimit;
dpplot beta,
 scheme(s2color)
 mcolor(red*1.5)
 msymbol(o)
 xline(0.030, lc(black*0.5) lp(dash))
 xline(0, lc(black*0.5) lp(solid))
 xlabel(-0.01(0.01)0.01)
 xtitle("回归系数估计", size(*0.8)) xlabel(, format(%4.2f) labsize(small))
 ytitle("频数", size(*0.8)) ylabel(, nogrid format(%4.1f) labsize(small))
 title("ΔROA")
 note("") caption("") graphregion(fcolor(white)) msize(vsmall);
#delimit cr
graph export "安慰剂检验_roa.png", width(1000) replace

**************************************************
use Startdata.dta, clear

global xlist  "size lev mfee top1 zindex sindex premium vcpe age"

winsor2 droa droe size lev mfee top1 zindex sindex premium, cuts(1 99) replace
gen roa= droa
gen roe= droe

cap erase "simulations_roe.dta"

permute registration_m beta = _b[registration_m], ///
 reps(500) rseed(123) saving("simulations_roe.dta"): ///
  reg roe registration_m $xlist i.ind_zz i.year, r

use "simulations_roe.dta", clear
#delimit;
dpplot beta,
 scheme(s2color)
 mcolor(red*1.5)
 msymbol(o)
 xline(0.054, lc(black*0.5) lp(dash))
 xline(0, lc(black*0.5) lp(solid))
 xlabel(-0.01(0.01)0.01)
 xtitle("回归系数估计", size(*0.8)) xlabel(, format(%4.2f) labsize(small))
 ytitle("频数", size(*0.8)) ylabel(, nogrid format(%4.1f) labsize(small))
 title("ΔROE")
 note("") caption("") graphregion(fcolor(white)) msize(vsmall);
 
#delimit cr
graph export "安慰剂检验_roe.png", width(1000) replace

***********************1.截面 psmdid******************************************
graph set window fontface     "times new roman"
graph set window fontfacesans "宋体"
set scheme s1color
clear
use Startdata.dta
xtset id year  

global xlist "size lev mfee top1 zindex sindex premium vcpe age" 

**# 1.1 卡尺最近邻匹配（1:1）
set  seed 0000
gen  norvar_1 = rnormal()
sort norvar_1
// PSM回归
psmatch2 treat $xlist , outcome(droa) logit neighbor(1) ties common ate caliper(0.05)
//核匹配
*psmatch2 treat $xlist , outcome(droa) logit kernel common ate

save psmdata.dta, replace
**# 1.2 平衡性检验
// 匹配后协变量的差异要变小
pstest, both graph saving(balancing_assumption, replace)
graph export "balancing_assumption.emf", replace
// 共同支撑域的样本要多、均衡
psgraph, saving(common_support, replace)
graph export "common_support.emf", replace


**# 1.3 倾向得分值的核密度图

sum _pscore if treat == 1, detail  // 处理组的倾向得分均值为0.7353

*- 匹配前

sum _pscore if treat == 0, detail //控制组倾向得分均值为0.4761

twoway(kdensity _pscore if treat == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stsans:核}""{stsans:密}""{stsans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stsans:匹配前的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(0.7353   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_cs_before, replace))                            ///
      (kdensity _pscore if treat == 0, lpattern(dash)),                    ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stsans:处理组}")                                      ///
             label(2 "{stsans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))

graph export "kensity_cs_before.emf", replace

discard

*- 匹配后

sum _pscore if treat == 0 & _weight != ., detail

twoway(kdensity _pscore if treat == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(qleanmono)                                              ///
              ytitle("{stsans:核}""{stsans:密}""{stsans:度}",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("{stsans:匹配后的倾向得分值}",                          ///
                     size(medlarge))                                         ///
              xline(0.7353   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_cs_after, replace))                             ///
      (kdensity _pscore if treat == 0 & _weight != ., lpattern(dash)),     ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)4, labsize(medlarge))                                       ///
      legend(label(1 "{stsans:处理组}")                                      ///
             label(2 "{stsans:控制组}")                                      ///
             size(medlarge) position(1) symxsize(10))

graph export "kensity_cs_after.emf", replace

discard //  Drop automatically loaded programs

gen common = _support
 *去掉不满足共同区域假定的观测值
drop if common == 0
 
**# 1.4 回归结果对比

use psmdata.dta, clear

*- 基准回归1（混合ols）
qui: reg droa registration  $xlist 
est store m1

*- 基准回归2（固定效应模型）

reg droa registration_m  $xlist i.year i.ind_zz, robust
est store m2

*- psm-did1（使用权重不为空的样本）
reg droa registration  $xlist i.year i.ind if _weight != ., robust
est store m3

*- psm-registration（使用满足共同支撑假设的样本）******此为论文汇报结果
reg droa registration_m $xlist i.year i.ind_zz if _support == 1, robust
est store m4

*- psm-did3（使用频数加权回归）
gen     weight  = _weight * 2
replace weight  = 1 if treat == 1 & _weight != .
keep if weight != .
expand  weight // 扩充样本, weight = 1样本为1个，weight = 2样本复制为2个
reg droa registration  $xlist  i.year i.ind, robust 
est store m5

*- 回归结果输出

local mlist_1 "m1 m2 m3 m4 m5"
reg2docx `mlist_1' using 截面匹配回归结果对比.docx, b(%6.4f) t(%6.4f)        ///
         scalars(n r2_a(%6.4f)) noconstant  replace                          ///
         mtitles("ols" "fe" "weight!=." "on_support" "weight_reg")           ///
         title("基准回归及截面psm-did结果")

********第四列即满足共同支撑的截面psm估计结果。

********窗口显示结果代码
use psmdata.dta, clear
reg droa registration  $xlist i.year i.ind if _weight != ., robust
outreg2 using 截面匹配回归结果对比.docx,replace tstat bdec(4) tdec(4) rdec(4) ctitle(weight!= .) keep(registration $xlist) addtext(ind fe, yes,year fe, yes)

reg droa registration  $xlist i.year i.ind if _support == 1,  robust
outreg2 using 截面匹配回归结果对比.docx,append tstat bdec(4) tdec(4) rdec(4) ctitle(on_support) keep(registration $xlist) addtext(ind fe, yes,year fe, yes)

gen     weight  = _weight * 2
replace weight  = 1 if treat == 1 & _weight != .
keep if weight != .
expand  weight // 扩充样本, weight = 1样本为1个，weight = 2样本复制为2个
reg droa registration  $xlist  i.year i.ind, robust 
outreg2 using 截面匹配回归结果对比.docx,append tstat bdec(4) tdec(4) rdec(4) ctitle(weight_reg) keep(registration $xlist) addtext(ind fe, yes,year fe, yes)

*****************************2.逐年匹配********************************************

use Startdata.dta, clear
gen roa= droa
gen roe= droe

**# 2.1 卡尺最近邻匹配（1:1）
// 从2004-2018逐年进行回归，preserve-store命令组合代表运行完中间代码后回到原始数据，capture为若代码错误，跳过去，进行运行
forvalue i = 2017/2022{
      preserve
          capture {
              keep if year == `i'
              set seed 0000
              gen  norvar_2 = rnormal()
              sort norvar_2
			  psmatch2 treat $xlist , outcome(droa) logit neighbor(1) ties common ate caliper(0.05)
              save `i'.dta, replace
              }
      restore
      }

clear all

use 2017.dta, clear

forvalue k =2018/2022 {
      capture {
          append using `k'.dta // 纵向拼接数据
          }
      }

save ybydata.dta, replace

**# 2.2 倾向得分值的核密度图

sum _pscore if treat == 1, detail  // 处理组的倾向得分均值为0.8050

*- 匹配前

sum _pscore if treat == 0, detail

twoway(kdensity _pscore if treat== 1, lpattern(solid) ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(s1mono)                                              ///
              ytitle("核""密""度",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("匹配前的倾向得分值",                          ///
                     size(medlarge))                                         ///
              xline(0.8050   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_yby_before, replace))                           ///
      (kdensity _pscore if treat == 0, lpattern(dash)),                    ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)3, labsize(medlarge))                                       ///
      legend(label(1 "处理组")                                      ///
             label(2 "控制组")                                      ///
             size(medlarge) position(1) symxsize(10))				///
			 
graph export "kensity_yby_before.png", replace

discard

*- 匹配后

sum _pscore if treat == 0 & _weight != ., detail

twoway(kdensity _pscore if treat == 1, lpattern(solid)                     ///
              lcolor(black)                                                  ///
              lwidth(thin)                                                   ///
              scheme(s1mono)                                              ///
              ytitle("核""密""度",                ///
                     size(medlarge) orientation(h))                          ///
              xtitle("匹配后的倾向得分值",                          ///
                     size(medlarge))                                         ///
              xline(0.8050   , lpattern(solid) lcolor(black))                ///
              xline(`r(mean)', lpattern(dash)  lcolor(black))                ///
              saving(kensity_yby_after, replace))                            ///
      (kdensity _pscore if treat == 0 & _weight != ., lpattern(dash)),     ///
      xlabel(     , labsize(medlarge) format(%02.1f))                        ///
      ylabel(0(1)3, labsize(medlarge))                                       ///
      legend(label(1 "处理组")                                      ///
             label(2 "控制组")                                      ///
             size(medlarge) position(1) symxsize(10))				///

graph export "kensity_yby_after.png", replace

discard
**# 2.3 逐年平衡性检验

*- 匹配前
// 逐年回归，提取变量回归系数
forvalue i = 2017/2022 {
          capture {
              qui: logit treat $xlist if year == `i',  vce(cluster ind_zz)
              est store ybyb`i'
              }
          }

local ybyblist ybyb2017 ybyb2018 ybyb2019 ybyb2020 ybyb2021 ybyb2022 

reg2docx `ybyblist' using 逐年平衡性检验结果_匹配前.docx, b(%6.4f) t(%6.4f)  ///
         scalars(r2_p(%6.4f)) noconstant replace                           ///
         mtitles("2017b" "2018b" "2019b" "2020b" "2021b" "2022b")            ///
         title("逐年平衡性检验_匹配前")

*- 匹配后

forvalue i = 2017/2022 {
          capture {
              qui: logit treat $xlist                                ///
                       if year == `i' & _weight != ., vce(cluster ind_zz)
              est store ybya`i'
              }
          }

local ybyalist ybya2017 ybya2018 ybya2019 ybya2020 ybya2021 ybya2022 

reg2docx `ybyalist' using 逐年平衡性检验结果_匹配后.docx, b(%6.4f) t(%6.4f)  ///
         scalars(r2_p(%6.4f)) noconstant replace                           ///
         mtitles("2017a" "2018a" "2019a" "2020a" "2021a" "2022a")                    ///
         title("逐年平衡性检验_匹配后")

**# 2.4 回归结果对比

	use ybydata.dta, clear


	*- 固定效应模型
	reg roa registration_m i.year i.ind_zz if _support == 1, robust
	outreg2 using 逐年匹配回归结果对比.docx,replace  bdec(4) tdec(4) rdec(4) ctitle(droa) keep(registration_m) addtext(ind fe, yes,year fe, yes)

	*- 
	reg roa registration_m  $xlist  i.year i.ind_zz if _support == 1, robust
	outreg2 using 逐年匹配回归结果对比.docx,append bdec(4) tdec(4) rdec(4) ctitle(droa) keep(registration_m $xlist ) addtext(ind fe, yes,year fe, yes)

	*- 固定效应模型
	reg roe registration_m i.year i.ind_zz if _support == 1, robust
	outreg2 using 逐年匹配回归结果对比.docx,append  bdec(4) tdec(4) rdec(4) ctitle(droe) keep(registration_m) addtext(ind fe, yes,year fe, yes)

	*- 
	reg roe registration_m  $xlist  i.year i.ind_zz if _support == 1, robust
	outreg2 using 逐年匹配回归结果对比.docx,append bdec(4) tdec(4) rdec(4) ctitle(droe) keep(registration_m $xlist ) addtext(ind fe, yes,year fe, yes)



********第二列即满足共同支撑的逐年psm估计结果。