PIE - the Perl Inference Engine

The Perl Inference Engine (PIE) is a simple Expert System (or rules engine). It's able to perform forwards, backwards and mixed-mode chaining. It's easily extensible, possibly to use a database for run-time information and storage rather than memory. It currently reads it's rules from an XML file (but could easily be modified to use other sources). PIE is particularly of use in conjunction with other applications, and is aimed at Perl programmers rather than end users.

Expert Systems offer an easy way to make computers able to arrive at conclusions in an intelligent manner. Indeed, with careful design, Expert System based applications can behave in a similar way to humans in order to arrive at conclusions. In general, Expert Systems operate on a "decision tree" called a Knowledge Base. The Expert System traverses this tree in an efficient manner, hopefully only following routes that most efficiently arrive at a conclusion.

Another useful feature of Expert Systems is to be able to ask them questions. That is, by setting them a goal to reach. For example, setting the goal of "internet access" would imply that the system must infer this information from whatever low level information and rules it has. Similarly, on arriving at a conclusion, it is possible to ask an expert system to explain how it arrived at that conclusion (intuitively, this is like "drilling down" through a conclusion).

PIE was originally conceived as a way to add high level information to low-level system and application availability information from a network monitoring application. In this capacity, it is broadly speaking only a rules engine, not performing anything particularly unique to Expert Systems. However, in this situation, it is easily able to determine if high level concepts such as "is the Internet working?" or "is Email working?" from low level information such as the individual servers and applications status. In this capacity it does add the ability to "drill down" and understand why a quantity is in the state described.

PIE is able to operate in far more demanding scenarios than described above. It supports the use of "confidence values" for any given value. That is, rather than working with certainties such as "yes" and "no", it can work with vagueries such as "probably" and "unlikely". It does this by adding "confidence" to certainties. For example, "yes(0.8)" suggests it's most probably "yes".