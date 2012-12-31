Communiqué is a library for planning messages in sequence diagrams written in
Ruby.

It resulted from the research I did for my Computer Science MS Thesis, which is
titled *Planning-Based Approach for Automating Sequence Diagram Generation*.
The basic idea is simple: under the right conditions, generating [UML sequence
diagrams][sd] is essentially a planning problem in disguise.

The "right conditions" are when [use cases][uc] and [class diagrams][cd] are
developed using the [Design by Contract][dbc] approach. When that is the case,
generating the sequence diagrams based on the other two models starts to look
very similar to solving a planning problem. In both cases, and despite some
differences in terminology, the same building blocks are present.

We provide more details about the basic idea along with a simple illustrative
example in our DMS 2012 paper, [Automating UML Sequence Diagram Generation by
Treating it as a Planning Problem][dms], which represents the early stages of
our research before we started developing Communiqué. Much more details about
Communiqué and the research behind it are available in my thesis, which I will
post a link to here once it gets officially approved.


[sd]: https://en.wikipedia.org/wiki/Sequence_diagram
[uc]: https://en.wikipedia.org/wiki/Use_case
[cd]: https://en.wikipedia.org/wiki/Class_diagram
[dbc]: https://en.wikipedia.org/wiki/Design_by_contract
[dms]: http://www.ksi.edu/seke/Proceedings/dms/DMS2012_Proceedings.pdf#page=141
