function get(context, params) {
    return cts.search(cts.collectionQuery("loader-report"), ["unfiltered", cts.indexOrder(cts.jsonPropertyReference("completedDate"), ["descending"])]).toArray()[0];
};

exports.GET = get;
