/* Copyright Pinnacle Research, 1993 */

#import <objc/objc.h>

#if _MK_ONLY_ONE_MTC_SUPPORTED

static MKMidi *mtcMidi = nil;

static void my_alarm_reply(port_t replyPort, int requestedTime, int actualTime)
{
    MKMidi *self = mtcMidi;
    if (!self)
	return;
    if (!XVARS(self)->tvs->alarmTimeValid || 
	XVARS(self)->tvs->intAlarmTime != requestedTime) 
      /* Filter out old messages. E.g. it's possible that a message will have been
       * sent to the port and at the same time, we try to cancel it. */
      return;
    XVARS(self)->tvs->alarmPending = NO;
    XVARS(self)->tvs->alarmTimeValid = NO;
    [XVARS(self)->tvs->synchConductor _runMTC:XVARS(self)->tvs->alarmTime 
     :actualTime * _MK_MIDI_QUANTUM_PERIOD];
}

static void my_exception_reply(port_t replyPort, int exception)
{
    MKMidi *self = mtcMidi;
    if (!self)
	return;
    [XVARS(self)->tvs->synchConductor _MTCException:exception];
}

#else
#warning "Incomplete implementation of multiple MTC conductors."
#endif

static void midiAlarm(msg_header_t *msg,void *self)
   /* Called by driver when midi alarm occurs. */
{
    int r;
    MIDIReplyFunctions recvStruct = {0,my_alarm_reply,0,0};
    r = MIDIHandleReply(msg,&recvStruct); 
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"midiAlarm");
} 

static void midiException(msg_header_t *msg,void *self)
   /* Called by driver when midi alarm occurs. */
{
    int r;
    MIDIReplyFunctions recvStruct = {0,0,my_exception_reply,0};
    r = MIDIHandleReply(msg,&recvStruct); 
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"midiException");
} 

@implementation MKMidi(Private)

+(BOOL)_disableThreadChange
{
    return addedPortsCount != 0;
}

-_setMTCOffset:(double)offset
  /* Time offset is the MTC time that corresponds with 0 clockTime.
   * E.g. offset 10 means that MTC is assumed to start at 10 seconds. 
   */
{
    mtcTimeOffset = offset;
    return self;
}

-(double)_time
  /* Same as -time, but doesn't add in deltaT in SCHEDULER_ADVANCE mode */
{
    int theTime;
    int r; 
    double t;
    if (deviceStatus == MK_devClosed)
      return 0;
    r = MIDIGetClockTime(XVARS(self)->devicePort,XVARS(self)->ownerPort,&theTime);
    if (r != KERN_SUCCESS) 
      _MKErrorf(MK_machErr,CLOCK_ERROR,midiDriverErrorString(r),
		"_time");
    t = theTime * _MK_MIDI_QUANTUM_PERIOD;
    if (XVARS(self)->tvs->synchConductor)
      t -= mtcTimeOffset;
    return t;
}

-_alarm:(double)requestedTime   
{
    int newIntTime;
    #define ISENDOFTIME(_x) (_x > (MK_ENDOFTIME - 1.0))
    if (ISENDOFTIME(requestedTime)) {
	if (deviceStatus == MK_devRunning) 
	  MIDIRequestAlarm(XVARS(self)->devicePort,XVARS(self)->ownerPort,PORT_NULL,0);
	XVARS(self)->tvs->alarmTimeValid = NO;
	XVARS(self)->tvs->alarmPending = NO;
	return self;
    }
    newIntTime = requestedTime * _MK_MIDI_QUANTUM;
    if (deviceStatus == MK_devRunning) {
	if (!XVARS(self)->tvs->alarmPending || 
	    XVARS(self)->tvs->intAlarmTime != newIntTime) {
	    MIDIRequestAlarm(XVARS(self)->devicePort,XVARS(self)->ownerPort,
			     XVARS(self)->tvs->alarmPort,newIntTime);
	    XVARS(self)->tvs->alarmPending = YES;
	}
    }
    XVARS(self)->tvs->alarmTimeValid = YES;
    XVARS(self)->tvs->intAlarmTime = newIntTime;
    XVARS(self)->tvs->alarmTime = requestedTime;
    return self;
}

- _setSynchConductor:aCond
  /* If status is closed, just store synchConductor.  
   * Otherwise set up alarm and exception ports.
   * The Conductor method that calls this ensures that
   * _setSynchConductor:nil is sent to anyone holding
   * the synch before _setSynchConductor:<non-nil> is sent.
   * Hence, we don't need to worry about that here.
   *
   * But MIDI's free can also call this with nil, so 
   * we have to be slightly more careful in this case
   * (i.e. we can't assume that we have the synch)
   */
{
    /* References to mtcMidi below will change if we ever support more than one synch */
    if (aCond) {
	XVARS(self)->tvs->midiObj = self;
	XVARS(self)->tvs->synchConductor = aCond;
	mtcMidi = self;
    } else {
	if (mtcMidi == self) { 
	    XVARS(self)->tvs->midiObj = nil;
	    XVARS(self)->tvs->synchConductor = aCond;
	    mtcMidi = nil;
	}
    }
    if (deviceStatus == MK_devClosed) /* We'll set up later */
      return self;
    if (aCond) {
	setUpMTC(self);
	if (deviceStatus == MK_devRunning)
	  resumeMidiClock(XVARS(self));
    }
    else tearDownMTC(self);
    return self;
}

@end

static int setUpMTC(MKMidi *self)
{
    int r = port_allocate(task_self(), &XVARS(self)->tvs->exceptionPort);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_machErr,OPEN_ERROR,mach_error_string( r), "setUpMTC");
	return r;
    }
    r = port_allocate(task_self(), &XVARS(self)->tvs->alarmPort);
    if (r != KERN_SUCCESS) {
	_MKErrorf(MK_machErr,OPEN_ERROR,mach_error_string( r), "setUpMTC");
	return r;
    }
    XVARS(self)->tvs->alarmTimeValid = NO;
    XVARS(self)->tvs->alarmPending = NO;
    // 2nd arg was midiAlarm, changed to self as it handleMachMessage - LMS
    _MKAddPort(XVARS(self)->tvs->alarmPort,self,MSG_SIZE_MAX,self, _MK_DPSPRIORITY);
    // 2nd arg was midiException, changed to self as it handleMachMessage - LMS
    _MKAddPort(XVARS(self)->tvs->exceptionPort,self,MSG_SIZE_MAX,self, _MK_DPSPRIORITY);
    addedPortsCount += 2;
    return r;
}

static int tearDownMTC(MKMidi *self)
{
    MIDIRequestExceptions(XVARS(self)->devicePort,XVARS(self)->ownerPort,PORT_NULL);
    _MKRemovePort(XVARS(self)->tvs->exceptionPort);
    deallocPort(&XVARS(self)->tvs->exceptionPort);
    /* Could call MIDIStopClock here? */
    MIDIRequestAlarm(XVARS(self)->devicePort,XVARS(self)->ownerPort,PORT_NULL,0);
    XVARS(self)->tvs->alarmPending = NO;
    XVARS(self)->tvs->alarmTimeValid = NO;
    _MKRemovePort(XVARS(self)->tvs->alarmPort);
    addedPortsCount -= 2;
    return deallocPort(&XVARS(self)->tvs->alarmPort);
}

static int resumeMidiClock(extraInstanceVars *ivars); /* Forward decl */


