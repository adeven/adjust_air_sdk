package com.adjust.sdk {
    public class AdjustSessionFail {
        private var message:String;
        private var timestamp:String;
        private var adid:String;
        private var jsonResponse:String;
        private var willRetry:Boolean;

        public function AdjustSessionFail(message:String, timestamp:String, adid:String, jsonResponse:String, willRetry:Boolean) {
            this.message = message;
            this.timestamp = timestamp;
            this.adid = adid;
            this.jsonResponse = jsonResponse;
            this.willRetry = willRetry;
        }

        // Getters
        public function getMessage():String {
            return this.message;
        }

        public function getTimeStamp():String {
            return this.timestamp;
        }

        public function getAdid():String {
            return this.adid;
        }

        public function getJsonResponse():String {
            return this.jsonResponse;
        }

        public function getWillRetry():Boolean {
            return this.willRetry;
        }
    }
}
