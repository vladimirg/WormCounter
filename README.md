# WormCounter

Automated counting of *C. elegans* worms from static images. The project is based on code from [Kauffman et al., 2011](https://www.jove.com/video/2490/c-elegans-positive-butanone-learning-short-term-long-term-associative), with some modifications and additions.

## Potential problems

For best accuracy, it's best to:

1. Maximize single worms.
2. Minimize large worms aggregates (in both size and number).
3. Count on the day of the experiment (dead worms undergo changes that make the contrast poorer).

Single worms are crucial for determining and appropriate average size (in pixels) per worm. If there are too few, this number can be biased, altering the worm count by quite a lot. For this reason, consider comparing the total worm areas in pixels, instead of the nominal worm count. 

# References

Kauffman, A., Parsons, L., Stein, G., Wills, A., Kaletsky, R., Murphy, C. *C. elegans* Positive Butanone Learning, Short-term, and Long-term Associative Memory Assays. *J. Vis. Exp.* (49), e2490, doi:10.3791/2490 (2011).