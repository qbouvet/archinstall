#! /usr/bin/python3


from config import * 
from utils import *

import RPi.GPIO as GPIO
import time

def _time() :         
    return int(time.perf_counter())

"""

    Author : Quentin Bouvet
"""
    
class PIRManager : 
    
    def __init__(self, cyclePeriod) :  
        #try :
        #    GPIO.cleanup()
        #    time.sleep(0.5)
        #except : 
        #    print("")
        GPIO.setmode(GPIO.BOARD)
        GPIO.setup(PIR_pin, GPIO.IN)
        self.callbacks = []
        self.activationSequenceIndex = 0
        self.lastCallbackTimestamp = _time()
        GPIO.add_event_detect(PIR_pin, GPIO.RISING, callback=self.global_callback)
        debug("PIR GPIO : init lastCallbackTimestamp to "+str(self.lastCallbackTimestamp))
        # debug("PIR GPIO : init cyclePeriod to "+str(self.cyclePeriod))
    
    def add_callback(self, callbackFunction) : 
        self.callbacks.append(callbackFunction)
        debug("PIR GPIO : adding callback : "+str(self.callbacks))
    
    def global_callback(self, pin) : 
        if (_time() < self.lastCallbackTimestamp+PIR_ACTIVATION_SEQUENCE[self.activationSequenceIndex]) : 
            debug("PIR GPIO : not enough time since last callbacks, ignoring activation ")       
            return      
        # If within slack for activation sequence
        if (_time() < self.lastCallbackTimestamp+PIR_ACTIVATION_SEQUENCE[self.activationSequenceIndex]+PIR_ACTIVATION_SLACK) : 
            if self.activationSequenceIndex < len(PIR_ACTIVATION_SEQUENCE) -1 : 
                self.activationSequenceIndex += 1
                debug("PIR GPIO : Iterating activation sequence :"+str(self.activationSequenceIndex))
            else :
                debug("PIR GPIO : reached end of actiavtion sequence")
        # else, reinitialize activation sequence
        else : 
            debug("PIR GPIO : resetting activation sequence index")
            self.activationSequenceIndex = 0
            
        debug("PIR GPIO : Running callbacks ... ")
        for f in self.callbacks : 
            f(pin)
        debug("PIR GPIO : callbacks done")
        self.lastCallbackTimestamp = _time()
    
    def cleanup(self) : 
        GPIO.cleanup()
    



