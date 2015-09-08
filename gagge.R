svp <- function (x){    #function to convert saturation vapour pressure units
    svp = 6.11*10**((7.5*x)/(237.7+x))    #saturation vapour pressure (hpa)
    svp_m = 0.750061683 * svp             #svp in  mmhg
    return (svp*10)
}

sub <- function(){
    tcl = 34        # T of clothes
    tr = 58         # Tmrt 
    chclo = 0.57
    tcr = 36.9
    tsk = 34
    facl = 1.0
    chc = 4.0
    ta = 28
    rm = 58.2
    pa = 101.3
    skbf = 6.3
    me = 0.2
    wk = 0.2 * rm
    esk = 1
    ht = 1.81
    wt = 70
    adu = 1.8
    alpha = 0.044 + 0.35/ (skbf-0.1386)
    ttsk = 33.7
    ttcr = 36.8
    bz = 0.1
    ttbm = 36
    time = 0.0
    exp_time = 60.0 # mins 
    step = 1 # mins
    
    tclold = tcl

    while (time < 1.0){
        dtim = 1.0 / exp_time   
        time = time + dtim
        print (time*exp_time)
        chr = 4*0.72*5.67*10^-8*((tcl+tr)/2+273.15)^3
        tcl = (chclo*tsk+facl*(chc*ta+chr*tr))/(chclo+facl*(chc+chr))
        # dry heat balance
        while (abs(tcl-tclold) > 0.01){
            chr = 4*0.72*5.67*10^-8*((tcl+tr)/2+273.15)^3
            tcl = (chclo*tsk+facl*(chc*ta+chr*tr))/(chclo+facl*(chc+chr))
            print (tcl)
            tclold=tcl  
        }
        # heat flow from clothing to environment
        dry = facl*(chc*(tcl-ta)+chr*(tcl-tr))
        
        # dry and latent respiratory heat losses
        eres = 0.017251 * rm * (5.8662-pa)
        cres=0.0014 * rm * (34.0-ta) # *ata*ff
        
        # heat flows to skin and core
        hfsk=(tcr-tsk)*(5.28+1.163*skbf)-dry-esk
        hfcr=rm-(tcr-tsk)*(5.28+1.163*skbf)-cres-eres-wk
        
        # thermal capacities
        tccr = 58.2*(1-alpha)*wt
        tcsk = 58.2*alpha*wt
        
        # temperature change in 1 min
        dtsk = (hfsk*adu)/tcsk
        dtcr = (hfcr*adu)/tccr
        dtbm = alpha * dtsk + (1-alpha)*dtcr
        tsk = tsk+dtsk
        tcr = tcr+dtcr
        
        if (tsk>ttsk) {
          warms = tsk - ttsk
          colds = 0
        }
        else {
          colds = ttsk - tsk
          warms = 0
        }
        
        if (tcr > ttcr) {
          warmc = tcr - ttcr
          coldc = 0
        }
        else{
          coldc = ttcr - tcr
          warmc = 0
        }
        
        ttbm = bz * ttsk+(1-bz)*ttcr
        tbm = alpha * tsk + (1-alpha)*tcr
        if (tbm > ttbm){
          warmb = tbm - ttbm
          coldb = 0
        }
        else{
          coldb = ttbm - tbm
          warmb = 0
        }
        
        # temperature regulation
        cdil = 200 #litres/(m2/h/K)
        cstr = 0.1
        csw = 170 # g/m2/hr
        skbfl = 90 # L/m2/hr
        regswl = 500
        
        dilat = cdil*warmc
        stric = cstr*colds
        skbf = (6.3+dilat)/(1+stric)
        # limits
        if (skbf < 0.5) {skbf = 0.5}
        if (skbf > skbfl) {skbf = skbfl}
        
        # skin-core proportion changes with blood flow
        alpha = 0.0417737+ 0.7451832/(skbf+0.58517)
        
        #sweating regulation
        regsw = csw*warmb**(warms/10.7)
        if (regsw > regswl) {
          regsw = regswl
        }
        ersw = 0.68 * regsw
        
        #shivering
        act = 59
        rm = act + 19.4 * colds*coldc
        
        #evaporation
        lr=15.1512*(tsk+273.15)/273.15
        im = 1
        icl = 1
        rt = (1/im) * (1/(lr*facl*chc)+1/(lr*chclo*icl))
        
        emax = (1/rt)*(svp(tsk)-pa)
        prsw = ersw / emax
        
        pdif = (1-prsw*0.6)
        edif = pdif*emax
        esk = ersw + edif
        pwet = esk/emax
        
        #dripping sweat
        eveff = 1
        
        if (pwet > eveff & emax > 0){
            pwet = eveff
            prsw = (eveff-0.06)/.94
            ersw = prsw / emax
            esk = ersw + edif
        }
        
        if (emax < 0) {
            pdif = 0
            edif = 0
            esk = emax
            pwet = eveff
            prsw = eveff
            ersw= 0
        }
        edrip = (regsw*0.68-prsw*emax)/0.68
        if (edrip < 0) {edrip = 0}
        
        #vapour pressure at skin
        vpsk = pwet * svp(tsk)+(1-pwet)*pa
        # rh at skin
        rhsk = vpsk/svp(tsk)
        print(tsk)
        }
    }
  
  sub2 <- function(){
  
    ctc = chc + chr
    to = ta + erf / ctc
    cloe = clo - (facl - 1)/(0.155 * facl * ctc)
    fcle = 1/(1 + 0.155 * ctc * cloe)
    fpcl = 1/(1 + (0.155/icl) * chc * chloe )
  
    hsk = ctc * fcle * (tsk - to) + pwet * lr * chc * fpcl * (svp(tsk) - pa)
  
    et = tsk - hsk / (ctc * fcle)
  
    # approximate ET* 
    while (err >= 0) {
      et = et + 0.1
      err = hsk - ctc * fcle * (tsk - et) - pwet * lr * chc * fpcl * (svp(tsk) - svp(et)/2)
    }
  
    # SET*
    chrs = chr
    chcs = 5.66 * (act/58.2-0.85)^0.39
    if (chcs < 3) {
      chcs = 3
    }
  
    rn = rm -wk
    clos = 1.3264/(rn/58.15+0.7383)-0.0953
    kclos = 0.25
    facls = 1+kclos + clos
    ctcs = chrs + chcs
    cloes = clos - (facls -1)/(0.155*facls*ctcs)
    fcles = 1/(1+0.155*ctcs*cloes)
    fpcls = 1/(1+(0.155/0.45)*chcs*cloes)
    
  }       
  
  sub()
  #sub2()