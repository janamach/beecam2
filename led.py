import RPi.GPIO as GPIO
import time

on_duration_sec = 5
times_per_sec = 600
freq = 1/times_per_sec

GPIO_NUMBER=21
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(GPIO_NUMBER,GPIO.OUT)

for i in  range (int(on_duration_sec/freq)):
	GPIO.output(GPIO_NUMBER,GPIO.HIGH)
	time.sleep(freq)
#	print(i)
	GPIO.output(GPIO_NUMBER,GPIO.LOW)
	time.sleep(freq)
