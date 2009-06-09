;;; -*- mode: xlisp; Clojure -*-

(use 'clojure.contrib.duck-streams)
(use 'clojure.contrib.pprint)
(require 'clojure.contrib.str-utils)
(require 'clojure.contrib.seq-utils)
(require 'clojure.contrib.math)

(def nss '(clojure.core clojure.contrib.str-utils clojure.contrib.seq-utils
	   clojure.contrib.duck-streams clojure.contrib.math clojure.contrib.pprint))

(defn get-publics [s]
  (sort-by #(.toString %) (keys (ns-publics (find-ns s)))))

(with-open [os (writer "./Clojure")]
  (doseq [s nss]
    (cl-format os "~A~%~{~A~%~}~%" s (get-publics s))))
