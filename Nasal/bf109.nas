var position = nil;
var pos2 = nil;
var pos3 = nil;
var pos4 = nil;
var airspeed = nil;
var revs = nil;
var ppitch = nil;
var mpress = nil;
var rstrain = 0;
var strain = 0;
var thrust = 0;
var ctemp = nil;
var cpos = 0;
var temp = nil;
var dtemp = nil;
var newtemp = nil;
var otemp = nil;
var visc = 0;
var npos = 0;
var rcount = 0;
var remaining = 0;
var starter_power = 0;
var alt = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");
var boost = props.globals.getNode("controls/engines/engine[0]/boost");
var blower = props.globals.getNode("controls/engines/engine[0]/blower");
var lowblower = 0.7;
var manpress = props.globals.getNode("engines/engine[0]/mp-osi");


var init = func {

  if (getprop("/controls/engines/engine[0]/on-startup-running") == 1) {
		magicstart();
	}
 
   main_loop();
   }

var main_loop = func {
#### set blower
	if (alt.getValue() > 13100 and blower.getValue() == 0 ) {
		interpolate (boost, 1,30);
		blower.setValue(1);
		}
	if (alt.getValue() < 13100 and blower.getValue() == 1 ) {
		interpolate (boost, lowblower,30);
		blower.setValue(0);
		}

#### set throttle
		if ( getprop("engines/engine[0]/running" )){
				var tmp = getprop("controls/engines/engine[0]/target-mp");
				var diffmp = ( tmp - manpress.getValue())/52;
				if (getprop("controls/engines/engine[0]/throttle-c") >= 0) {
						interpolate("controls/engines/engine[0]/throttle-c",getprop("controls/engines/engine[0]/throttle-c") + diffmp, 0.1);
				} else {
						setprop ("controls/engines/engine[0]/throttle-c", 0);
				}
		}

#### automatic slats
  airspeed = getprop("/velocities/airspeed-kt");
    revs = getprop("/engines/engine[0]/rpm");
    if (airspeed < 110) {
      setprop("/controls/flight/slats", 1.0);
      } else {
        setprop("/controls/flight/slats", 0.0);
     }
#### prop-adjust  

  if (getprop("/controls/engines/engine[0]/prop-auto") == 1) {  

    ppitch = getprop("/controls/engines/engine[0]/propeller-adjust");
    mpress = getprop("/engines/engine/mp-osi");  

      if (revs / mpress < 68.0)  {
          setprop("/controls/engines/engine[0]/propeller-adjust", ppitch + 0.003);
          }
      if (revs / mpress > 68.0)  {
          setprop("/controls/engines/engine[0]/propeller-adjust", ppitch - 0.003);
          }
    
### kill engine when overreved
  }
#  rev2 = getprop("/engines/engine[0]/rpm");
  rstrain = getprop("/engines/engine[0]/rev-strain");
  if (rstrain > 350000) {
    setprop("/engines/engine[0]/overrev", 1);
    setprop("/engines/engine[0]/running", 0);
    setprop("/engines/engine[0]/out-of-fuel", 1);
    setprop("/consumables/fuel/tank[0]/selected",0);
    interpolate ("/engines/engine[0]/fuel-press", 0, 1);
    }
  if (revs > 2600) {
    strain = revs - 2600;
    setprop("/engines/engine[0]/rev-strain", rstrain + strain);
  }
  
### check fuel state for reserve light and 

			if (getprop ("consumables/fuel/tank[0]/level-norm") < 0.2 ) {
					setprop ("consumables/fuel/on-reserve", 1);
			} else {
					if (getprop ("consumables/fuel/on-reserve") == 1 ) {
							setprop ("consumables/fuel/on-reserve", 0);
					}
			}
			if (getprop ("consumables/fuel/tank[1]/level-norm") < 0.1 and ("consumables/fuel/tank[1]/selected") == 1 ) {
					setprop ("consumables/fuel/tank[1]/selected", 0 );
			}

### coolant temp
  if (getprop("/engines/engine[0]/running") == 1) {
#    rev = getprop("/engines/engine[0]/rpm");
    thrust = getprop("/engines/engine[0]/prop-thrust");
#    print ("#");
#    print ( thrust );
    ctemp = getprop("/engines/engine[0]/coolant-temp-degc");
#    print ( ctemp );
    cpos = getprop("/controls/engines/engine[0]/cowl-flaps-norm");
#    print ( cpos );
    airspeed = getprop("/velocities/airspeed-kt");
#    print ( airspeed );
    temp = getprop("/environment/temperature-degc");
#    print ( temp );
    dtemp = 0.008*((0.007*thrust+temp)-0.2*(1.5*(airspeed*cpos+55)));
#    print ( dtemp );
    newtemp = (ctemp + dtemp);
#    print (newtemp);
    setprop ("/engines/engine[0]/coolant-temp-degc" , newtemp);

### fuel pressure
		interpolate ("engines/engine[0]/fuel-press", 1.5, 3);

### oil and viscosity


    otemp = getprop("engines/engine[0]/oil-temperature-degf");
    visc = getprop("engines/engine[0]/oil-visc");
		interpolate ("engines/engine[0]/oil-press", 8.2 - 2*visc, 1);
    if (visc < 1.0 ) {
      setprop("engines/engine[0]/oil-visc", visc + 0.002);
			setprop("engines/engine[0]/oiltempc", otemp *visc);
      if (revs > 1000) {
           setprop("/engines/engine[0]/rev-strain", rstrain + (600/visc));
      }
    } else {
		setprop("engines/engine[0]/oiltempc", otemp);
	}
	   
### kill engine when overheated

    if (newtemp > 135) {
      setprop("/engines/engine[0]/overheat", 1);
      setprop("/engines/engine[0]/running", 0);
      setprop("/engines/engine[0]/out-of-fuel", 1);
   		setprop("/consumables/fuel/tank[0]/selected",0);
      interpolate ("/engines/engine[0]/fuel-press", 0, 3);
      interpolate ("/engines/engine[0]/oil-press", 0, 1);
    }
  }
### automatic coolflap adjustment

  if (getprop("/controls/engines/engine[0]/coolflap-auto") == 1) {
    ctemp = getprop("/engines/engine[0]/coolant-temp-degc");
    cpos = getprop("/controls/engines/engine[0]/cowl-flaps-norm");
    npos = cpos;
    if (ctemp < 65) {
      npos = cpos - 0.05;
      } 
      if (ctemp > 85) {
      npos = cpos + 0.05;
      }
    
    interpolate ("/controls/engines/engine[0]/cowl-flaps-norm" , npos, 0.5 );
  }
  
  settimer(main_loop, 0.2)
  
} 


var toggle_tailhook = func {
  if(getprop("/controls/gear/tailhook/position-norm") > 0) {
      hook.close();
  } else {
      hook.open();
  }
}


var toggle_canopy = func {
  canopy = aircraft.door.new ("/controls/canopy/",3);
  if(getprop("/controls/canopy/position-norm") > 0) {
      canopy.close();
  } else {

      canopy.open();
  }
}

var toggle_revi = func {
  revi = aircraft.door.new ("/controls/armament/revi",2);
  if(getprop("/controls/armament/revi/position-norm") > 0) {
      revi.close();
  } else {

      revi.open();
  }
}

var fire_MG = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
     setprop("/controls/armament/trigger", 1);
		if (getprop("/sim/weight[1]/weight-lb") == 110)  {
    	 setprop("/controls/armament/trigger2", 1);
		}
     } 
}
var stop_MG = func {
     setprop("/controls/armament/trigger", 0); 
     setprop("/controls/armament/trigger2", 0);
}

var fire_cannon = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
     setprop("/controls/armament/trigger1", 1);
     } 
}
var stop_cannon = func {
     setprop("/controls/armament/trigger1", 0); 
}

var fire_wgr = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
  rcount=getprop("/sim/weight[1]/weight-lb");
  if(rcount > 20){
    if(rcount == 270)  {
     setprop("/controls/armament/wgr", 1)
     } 
  setprop("sim/weight[1]/weight-lb", rcount - 250.0);
  setprop("sim/weight[2]/weight-lb", rcount - 250.0);
  }
 }
}

var jett_center_stores = func {
		var center_load = getprop("sim/weight[0]/selected");
		print (center_load);
		if (center_load == "Droptank") {
			 print ("dropping tank");
   	   setprop("/controls/armament/station/release-tank", 1);
  	   setprop("/sim/weight[0]/selected","none");
 	     setprop("/consumables/fuel/tank[1]/selected",0);
 	     setprop("/consumables/fuel/tank[1]/level-gal_us",0);
   		 setprop("/consumables/fuel/tank[1]/level-lbs",0);
   		 setprop("/consumables/fuel/tank[1]/capacity-gal_us",0);
		} 
		if (center_load != "none") {
				print ("dropping everything else");
				setprop("/controls/armament/station/release", 1);
		}
}


var drop_tank = func {
  rcount=getprop("/sim/weight[0]/weight-lb");
  if(rcount > 49){

     } 
 }

var starter = func {
	starter_power = getprop("/systems/electrical/volts");
	if(starter_power == nil)
		{starter_power = 0;}
	if (arg[0] == 1){
		if( starter_power > 5.0){ 
			setprop("/controls/engines/engine[0]/starter",1);
		}
		}else{
			setprop("/controls/engines/engine[0]/starter",0);}	
	}

var fuel_jettison = func {
  remaining = getprop("consumables/fuel/tank[0]/level-gal_us");
  interpolate("consumables/fuel/tank[0]/level-gal_us", (remaining-5),1);
}

var open_coolflaps = func {
      setprop("/controls/engines/engine[0]/coolflap-auto",0);
      interpolate("controls/engines/engine[0]/cowl-flaps-norm",1,4);
      setprop("/controls/engines/engine[0]/radlever",2);
}
var close_coolflaps = func {
      setprop("/controls/engines/engine[0]/coolflap-auto",0);
      interpolate("controls/engines/engine[0]/cowl-flaps-norm",0,4);
      setprop("/controls/engines/engine[0]/radlever",0);
}
var auto_coolflaps = func {
      setprop("/controls/engines/engine[0]/radlever",1);
      setprop("/controls/engines/engine[0]/coolflap-auto",1);
}

var magicstart = func {
    setprop("/consumables/fuel/tank[0]/selected",1);
    setprop("/controls/engines/engine[0]/magnetos",3);
    setprop("/controls/engines/engine[0]/coolflap-auto",1);
    setprop("/controls/engines/engine[0]/radlever",1);
    setprop("/controls/engines/engine[0]/propeller-adjust",0.5);
    setprop("/engines/engine[0]/oil-visc",1);
    setprop("/engines/engine[0]/rpm",800);
    setprop("/engines/engine[0]/engine-running",1);
    setprop("/engines/engine[0]/out-of-fuel",0);
    setprop("/engines/engine[0]/coolant-temp-degc",40);
    setprop("/controls/fuel/switch-position",0);
}

    setlistener("/controls/fuel/switch-position", func(n) {
	position=n.getValue();
    setprop("/consumables/fuel/tank[0]/selected",0);
    setprop("/consumables/fuel/tank[1]/selected",0);
        if(position >= 0.0){
           if(getprop("/engines/engine[0]/overrev") == 0){
             if(getprop("/engines/engine[0]/overheat") == 0){
               setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
  }
      };
    };
   },1);



    setlistener("/controls/engines/engine[0]/primer", func(n) {
	pos2=n.getValue();
        if(pos2 > 0.9){

               setprop("/engines/engine[0]/out-of-fuel",0);
      
    };
   },1);

    setlistener("/controls/engines/engine[0]/throttle", func(n) {
				pos3=n.getValue();
				setprop ("controls/engines/engine[0]/target-mp" ,52 * pos3);
        if(pos3 >= 0.7){
           setprop("controls/engines/engine[0]/prop-auto",1);
				};
   },1);

    setlistener("engines/engine[0]/running", func(n) {
	pos4=n.getValue();
        if(pos4 == 0.0){
           interpolate ("engines/engine[0]/fuel-press",0,3);
           interpolate ("engines/engine[0]/oil-press",0,3);
    };
   },1);

    setlistener("controls/engines/engine[0]/radlever", func(n) {
	pos3=n.getValue();
        if(pos3 == 0){
      		close_coolflaps();
				}
        if(pos3 == 1){
      		auto_coolflaps();
				}
        if(pos3 == 2){
      		open_coolflaps();
   		 };
   },1);

    setlistener("sim/weight[0]/selected", func(n) {
	pos4=n.getValue();
	dropped = getprop("controls/armament/station[0]/release");
#	print (dropped , pos4 );
		if (pos4 !="none") {
				if ( pos4 != "Droptank") {
					setprop ("controls/armament/fuse-control", 1);
				}
				if (dropped == 0 ) { 
		        if(pos4 == "Droptank"){
								setprop ("consumables/fuel/tank[1]/level-gal_us",86);						
						}
				}
    };
   },0,0);


setlistener("/sim/signals/fdm-initialized",init);

var flash_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/bf109/lighting/flash-l", [0.03, 0.044], flash_trigger);
aircraft.light.new("sim/model/bf109/lighting/flash-r", [0.024, 0.04], flash_trigger);

var flash1_trigger = props.globals.getNode("controls/armament/trigger1", 0);
aircraft.light.new("sim/model/bf109/lighting/flash-f", [0.05, 0.052], flash1_trigger);

aircraft.livery.init("Aircraft/bf109/Models/Liveries", "sim/model/livery/variant");
var hook = aircraft.door.new ("/controls/gear/tailhook/",3);
var logo_dialog = gui.OverlaySelector.new("Select Logo", "Aircraft/Generic/Logos", "sim/model/logo/name", nil, "sim/multiplay/generic/string");
