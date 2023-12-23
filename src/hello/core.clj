(ns hello.core
  (:require [clojure.string :as string]
	    [ring.adapter.jetty :refer [run-jetty]])
  (:gen-class))

(def body
  (str "Hello from " (string/upper-case "clojure!!!")))

(defn handler [request]
  {:status 200
   :headers {"Content-Type" "text/plain; charset=UTF-8"}
   :body body})

(defn -main [& args]
  (run-jetty handler {:port (Integer/valueOf (or (System/getenv "port") "3000"))}))
